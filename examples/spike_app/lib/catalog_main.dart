import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart'
    show AppColorPalette;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:systematic_catalog/systematic_catalog.dart';
import 'package:systematic_ui/systematic_ui.dart';

import 'adapters/flow_adapters.dart';
import 'adapters/note_tile_adapter.dart';
import 'adapters/notes_adapter.dart';
import 'adapters/rename_dialog_adapter.dart';
import 'adapters/search_adapter.dart';
import 'adapters/status_adapter.dart';
import 'adapters/tabs_adapter.dart';
import 'adapters/workspace_switch_adapter.dart';
import 'flow/flow_cubit.dart';
import 'infrastructure/ui_flow.dart';
import 'l10n/app_localizations.dart';
import 'notes/notes_cubit.dart';
import 'rename/rename_form_cubit.dart';
import 'search/search_cubit.dart';
import 'status/status_cubit.dart';
import 'tabs/tabs_cubit.dart';
import 'theme/app_theme.dart';
import 'views/confirm_dialog_view.dart';
import 'views/home_view.dart';
import 'views/tag_chip.dart';
import 'views/workspace_switch_view.dart';
import 'workspace/workspace_cubit.dart';

/// Catalog-only actions: plain no-op implementations, no cubits or scopes.
class _NoopNotes extends NoOpActions implements NotesActions {}

class _NoopSearch extends NoOpActions implements SearchActions {}

class _NoopWorkspace extends NoOpActions implements WorkspaceActions {}

class _NoopRename extends NoOpActions implements RenameFormActions {}

class _NoopFlow extends NoOpActions implements FlowActions {}

class _NoopTabs extends NoOpActions implements TabsActions {}

final _notes = _NoopNotes();
final _search = _NoopSearch();
final _workspace = _NoopWorkspace();
final _rename = _NoopRename();
final _flow = _NoopFlow();
final _tabs = _NoopTabs();

/// Owns a catalog TextEditingController, so each one is disposed with its
/// entry. The builder receives the controller.
class _WithController extends StatefulWidget {
  const _WithController({
    required this.text,
    required this.builder,
  });

  final String text;
  final Widget Function(TextEditingController) builder;

  @override
  State<_WithController> createState() => _WithControllerState();
}

class _WithControllerState extends State<_WithController> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

/// Label above a widget entry. Also gives each entry a visible exact name.
Widget _labelled(String name, Widget child) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(name), child],
    );

/// Label above a screen entry; the screen fills the frame below the label.
Widget _labelledScreen(String name, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name),
        Expanded(child: child),
      ],
    );

Widget _catalogTile(String id) => NoteTileAdapter.assemble(
      NoteTileData(
        id: id,
        title: 'Note $id',
        tag: 'tag1',
        selected: id == 'b',
      ),
      _notes,
      onRename: () {},
      onDelete: () {},
    );

Widget _notesList(String tabId, NoteListData data) => NotesAdapter.assemble(
      tabId,
      data,
      _catalogTile,
      onDeleteSelected: () {},
      onRetry: () {},
    );

Widget _home(SearchPanelData data) => HomeView(
      header: WorkspaceSwitchAdapter.assemble(
        const WorkspaceSwitchData(current: 'A', options: ['A', 'B']),
        _workspace,
      ),
      tabs: TabsAdapter.assemble(
        TabStripData(tabs: kTabs, active: 'tab1'),
        _tabs,
        const Text('Body'),
      ),
      search: _WithController(
        text: data.hasQuery ? 'alpha' : '',
        builder: (c) => SearchAdapter.assemble(data, _search, c),
      ),
      status: StatusAdapter.assemble(const StatusData(tick: 3)),
      onStartFlow: () {},
    );

List<CatalogEntry> catalogEntries() => [
      CatalogEntry.fromSamples<TagChipData>(
        name: 'TagChip',
        kind: CatalogKind.widget,
        samples: TagChipData.samples(),
        build: (data) => _labelled(
          'TagChip',
          TagChip(data: data, onTap: () {}),
        ),
      ),
      CatalogEntry.fromSamples<NoteTileData>(
        name: 'NoteTile',
        kind: CatalogKind.widget,
        samples: NoteTileData.samples(),
        build: (data) => _labelled(
          'NoteTile',
          NoteTileAdapter.assemble(data, _notes, onRename: () {}, onDelete: () {}),
        ),
      ),
      CatalogEntry.fromSamples<NoteListData>(
        name: 'NoteListView',
        kind: CatalogKind.widget,
        samples: NoteListData.samples(),
        build: (data) => _labelled('NoteListView', _notesList('tab1', data)),
      ),
      CatalogEntry.fromSamples<TabStripData>(
        name: 'TabStripView',
        kind: CatalogKind.widget,
        samples: TabStripData.samples(),
        build: (data) => _labelled(
          'TabStripView',
          TabsAdapter.assemble(
            data,
            _tabs,
            const Text('Body'),
          ),
        ),
      ),
      CatalogEntry.fromSamples<SearchPanelData>(
        name: 'SearchPanelView',
        kind: CatalogKind.widget,
        samples: SearchPanelData.samples(),
        build: (data) => _labelled(
          'SearchPanelView',
          _WithController(
            text: data.hasQuery ? 'abc' : '',
            builder: (c) => SearchAdapter.assemble(data, _search, c),
          ),
        ),
      ),
      CatalogEntry.fromSamples<StatusData>(
        name: 'StatusView',
        kind: CatalogKind.widget,
        samples: StatusData.samples(),
        build: (data) =>
            _labelled('StatusView', StatusAdapter.assemble(data)),
      ),
      CatalogEntry.fromSamples<WorkspaceSwitchData>(
        name: 'WorkspaceSwitchView',
        kind: CatalogKind.widget,
        samples: WorkspaceSwitchData.samples(),
        build: (data) => _labelled(
          'WorkspaceSwitchView',
          WorkspaceSwitchAdapter.assemble(data, _workspace),
        ),
      ),
      CatalogEntry.fromSamples<ConfirmDialogData>(
        name: 'ConfirmDialogView',
        kind: CatalogKind.widget,
        samples: ConfirmDialogData.samples(),
        build: (data) => _labelled(
          'ConfirmDialogView',
          ConfirmDialogView(data: data, onConfirm: () {}, onCancel: () {}),
        ),
      ),
      CatalogEntry.fromSamples<RenameFormData>(
        name: 'RenameDialogView',
        kind: CatalogKind.widget,
        samples: RenameFormData.samples(),
        build: (data) => _labelled(
          'RenameDialogView',
          _WithController(
            text: data.valid ? 'Alpha' : '',
            builder: (c) => RenameDialogAdapter.assemble(
              data,
              _rename,
              c,
              onSave: () {},
              onCancel: () {},
            ),
          ),
        ),
      ),
      CatalogEntry.fromSamples<SearchPanelData>(
        name: 'HomeView',
        kind: CatalogKind.screen,
        samples: SearchPanelData.samples(),
        build: (data) => _labelledScreen('HomeView', _home(data)),
      ),
      CatalogEntry.fromSamples<FlowNameData>(
        name: 'StartView',
        kind: CatalogKind.screen,
        samples: FlowNameData.samples(),
        build: (data) => _labelledScreen(
          'StartView',
          FlowStartAdapter.assemble(data, _flow, onNext: () {}),
        ),
      ),
      CatalogEntry.fromSamples<FlowNameData>(
        name: 'ConfirmView',
        kind: CatalogKind.screen,
        samples: FlowNameData.samples(),
        build: (data) => _labelledScreen(
          'ConfirmView',
          FlowConfirmAdapter.assemble(data, onBack: () {}),
        ),
      ),
    ];

/// The catalog's theme: the palette with the side panel's colour overrides,
/// and the spacing, size and brightness controls applied to the sizes.
ThemeData _catalogTheme(CatalogTokens tokens, Brightness brightness) {
  final palette = AppColorPalette(
    colors: {...kPalette.colors, ...tokens.colorOverrides},
  );
  final service = ThemeService(
    lightPalette: palette,
    darkPalette: palette.symmetricPalette,
  )..setDarkMode(brightness == Brightness.dark);
  const radii = (tiny: 2.0, small: 8.0, medium: 16.0, large: 24.0);
  final sizes = const SystematicSizes.standard().copyWith(
    space: 8 * tokens.spacingScale,
    spaceHalf: 4 * tokens.spacingScale,
    radiusTiny: radii.tiny * tokens.sizeScale,
    radiusSmall: radii.small * tokens.sizeScale,
    radiusMedium: radii.medium * tokens.sizeScale,
    radiusLarge: radii.large * tokens.sizeScale,
  );
  return AppTheme.build(
    palette: service.currentPalette,
    sizes: sizes,
    brightness: brightness,
    fontFamily: tokens.fontFamily,
  );
}

Widget catalogApp() {
  final labels = AppLabelResolver();
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    builder: (context, child) => LabelScope(
      resolver: labels.update(AppLocalizations.of(context)!),
      child: child ?? const SizedBox.shrink(),
    ),
    home: CatalogPage(
      entries: catalogEntries(),
      themeBuilder: _catalogTheme,
      paletteColors: kPalette.colors,
    ),
  );
}

void main() => runApp(catalogApp());
