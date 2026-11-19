import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:systematic_ui/systematic_ui.dart';

import 'adapters/flow_adapters.dart';
import 'adapters/search_adapter.dart';
import 'adapters/status_adapter.dart';
import 'adapters/tabs_adapter.dart';
import 'adapters/workspace_host_adapter.dart';
import 'adapters/workspace_switch_adapter.dart';
import 'data/in_memory_notes_source.dart';
import 'infrastructure/error_capture.dart';
import 'infrastructure/ui_flow.dart';
import 'l10n/app_localizations.dart';
import 'notes/notes_source.dart';
import 'scopes.dart';
import 'theme/app_theme.dart';
import 'views/home_view.dart';

/// Composition root: builds the session scope, the theme and the router.
class SpikeApp extends StatefulWidget {
  const SpikeApp({
    super.key,
    this.tick = const Duration(seconds: 1),
    this.initialLocation = '/',
    this.notesSource,
  });

  final Duration tick;
  final String initialLocation;

  /// Where notes come from. Defaults to [InMemoryNotesSource].
  final NotesSource? notesSource;

  @override
  State<SpikeApp> createState() => _SpikeAppState();
}

class _SpikeAppState extends State<SpikeApp> {
  late final GoRouter _router;
  late final NotesSource _notesSource =
      widget.notesSource ?? const InMemoryNotesSource();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _labels = AppLabelResolver();
  late final IUiFlowService _ui = UiFlowService(
    resolver: _labels,
    feedback: SnackBarFeedback(_messengerKey),
    loading: const NoLoading(),
  );
  final _themeService = ThemeService(
    lightPalette: kPalette,
    darkPalette: kPalette.symmetricPalette,
  );

  @override
  void initState() {
    super.initState();
    startErrorCapture();
    _router = GoRouter(
      initialLocation: widget.initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => WorkspaceHostAdapter(
            child: HomeView(
              header: const WorkspaceSwitchAdapter(),
              tabs: const TabsAdapter(),
              search: const SearchAdapter(),
              status: const StatusAdapter(),
              onStartFlow: () => context.go('/start'),
            ),
          ),
        ),
        ShellRoute(
          builder: (context, state, child) => ScopeProvider<FlowScope>(
            create: FlowScope.new,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/start',
              builder: (context, state) => const FlowStartAdapter(),
            ),
            GoRoute(
              path: '/start/confirm',
              builder: (context, state) => const FlowConfirmAdapter(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _themeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopeProvider<SessionScope>(
      create: () => SessionScope(
        tick: widget.tick,
        notesSource: _notesSource,
        ui: _ui,
      ),
      child: ListenableBuilder(
        listenable: _themeService,
        builder: (context, _) => MaterialApp.router(
          scaffoldMessengerKey: _messengerKey,
          theme: AppTheme.build(
            palette: _themeService.currentPalette,
            sizes: const SystematicSizes.standard(),
            brightness: Brightness.light,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          builder: (context, child) {
            UiScaler.instance.init(context);
            // The delegates above make AppLocalizations available here.
            final l10n = AppLocalizations.of(context)!;
            return LabelScope(
              resolver: _labels.update(l10n),
              child: child ?? const SizedBox.shrink(),
            );
          },
          routerConfig: _router,
        ),
      ),
    );
  }
}
