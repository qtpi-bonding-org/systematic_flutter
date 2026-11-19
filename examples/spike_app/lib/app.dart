import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'adapters/flow_adapters.dart';
import 'adapters/search_adapter.dart';
import 'adapters/status_adapter.dart';
import 'adapters/tabs_adapter.dart';
import 'adapters/workspace_host_adapter.dart';
import 'adapters/workspace_switch_adapter.dart';
import 'scopes.dart';
import 'views/home_view.dart';

/// Composition root: builds the session scope and the router.
class SpikeApp extends StatefulWidget {
  const SpikeApp({
    super.key,
    this.tick = const Duration(seconds: 1),
    this.initialLocation = '/',
  });

  final Duration tick;
  final String initialLocation;

  @override
  State<SpikeApp> createState() => _SpikeAppState();
}

class _SpikeAppState extends State<SpikeApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScopeProvider<SessionScope>(
      create: () => SessionScope(tick: widget.tick),
      child: MaterialApp.router(
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        routerConfig: _router,
      ),
    );
  }
}
