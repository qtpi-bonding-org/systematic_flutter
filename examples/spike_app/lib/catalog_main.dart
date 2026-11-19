import 'package:flutter/material.dart';
import 'package:systematic_catalog/systematic_catalog.dart';

import 'adapters/flow_adapters.dart';
import 'adapters/note_tile_adapter.dart';
import 'adapters/notes_adapter.dart';
import 'adapters/rename_dialog_adapter.dart';
import 'adapters/search_adapter.dart';
import 'adapters/status_adapter.dart';
import 'adapters/tabs_adapter.dart';
import 'adapters/workspace_switch_adapter.dart';
import 'flow/flow_cubit.dart';
import 'notes/notes_cubit.dart';
import 'rename/rename_form_cubit.dart';
import 'search/search_cubit.dart';
import 'views/confirm_dialog_view.dart';
import 'views/home_view.dart';
import 'views/tag_chip.dart';
import 'workspace/workspace_cubit.dart';

/// Catalog-only actions: plain no-op implementations, no cubits or scopes.
class _NoopNotes extends NoOpActions implements NotesActions {}

class _NoopSearch extends NoOpActions implements SearchActions {}

class _NoopWorkspace extends NoOpActions implements WorkspaceActions {}

class _NoopRename extends NoOpActions implements RenameFormActions {}

class _NoopFlow extends NoOpActions implements FlowActions {}

final _notes = _NoopNotes();
final _search = _NoopSearch();
final _workspace = _NoopWorkspace();
final _rename = _NoopRename();
final _flow = _NoopFlow();

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

Widget _notesList(String tabId, List<String> ids) => NotesAdapter.assemble(
      tabId,
      NoteListData(ids),
      _catalogTile,
      onDeleteSelected: () {},
    );

Widget _home({required bool online, required bool hasQuery}) => HomeView(
      header: WorkspaceSwitchAdapter.assemble('A', _workspace),
      tabs: TabsAdapter.assemble(
        TabsAdapter.tabs,
        'tab1',
        (_) {},
        _notesList('tab1', const ['tab1-1', 'tab1-2']),
      ),
      search: SearchAdapter.assemble(
        SearchPanelData(hasQuery: hasQuery, online: online),
        _search,
        TextEditingController(text: hasQuery ? 'alpha' : ''),
      ),
      status: StatusAdapter.assemble(3),
      onStartFlow: () {},
    );

List<CatalogEntry> catalogEntries() => [
      CatalogEntry(
        name: 'TagChip',
        kind: CatalogKind.widget,
        states: {
          'tag1': (_) => _labelled(
                'TagChip',
                TagChip(label: 'tag1', onTap: () {}),
              ),
          'tag2': (_) => _labelled(
                'TagChip',
                TagChip(label: 'tag2', onTap: () {}),
              ),
        },
      ),
      CatalogEntry(
        name: 'NoteTile',
        kind: CatalogKind.widget,
        states: {
          'default': (_) => _labelled(
                'NoteTile',
                NoteTileAdapter.assemble(
                  const NoteTileData(
                    id: 'a',
                    title: 'Alpha',
                    tag: 'tag1',
                    selected: false,
                  ),
                  _notes,
                  onRename: () {},
                  onDelete: () {},
                ),
              ),
          'selected': (_) => _labelled(
                'NoteTile',
                NoteTileAdapter.assemble(
                  const NoteTileData(
                    id: 'a',
                    title: 'Alpha',
                    tag: 'tag1',
                    selected: true,
                  ),
                  _notes,
                  onRename: () {},
                  onDelete: () {},
                ),
              ),
        },
      ),
      CatalogEntry(
        name: 'NoteListView',
        kind: CatalogKind.widget,
        states: {
          'empty': (_) => _labelled('NoteListView', _notesList('tab1', const [])),
          'full': (_) => _labelled(
                'NoteListView',
                _notesList('tab1', const ['a', 'b', 'c']),
              ),
        },
      ),
      CatalogEntry(
        name: 'TabStripView',
        kind: CatalogKind.widget,
        states: {
          'tab1': (_) => _labelled(
                'TabStripView',
                TabsAdapter.assemble(
                  TabsAdapter.tabs,
                  'tab1',
                  (_) {},
                  const Text('Body'),
                ),
              ),
          'tab2': (_) => _labelled(
                'TabStripView',
                TabsAdapter.assemble(
                  TabsAdapter.tabs,
                  'tab2',
                  (_) {},
                  const Text('Body'),
                ),
              ),
        },
      ),
      CatalogEntry(
        name: 'SearchPanelView',
        kind: CatalogKind.widget,
        states: {
          'empty-online': (_) => _labelled(
                'SearchPanelView',
                SearchAdapter.assemble(
                  const SearchPanelData(hasQuery: false, online: true),
                  _search,
                  TextEditingController(),
                ),
              ),
          'typing-offline': (_) => _labelled(
                'SearchPanelView',
                SearchAdapter.assemble(
                  const SearchPanelData(hasQuery: true, online: false),
                  _search,
                  TextEditingController(text: 'abc'),
                ),
              ),
        },
      ),
      CatalogEntry(
        name: 'StatusView',
        kind: CatalogKind.widget,
        states: {
          'tick 0': (_) => _labelled('StatusView', StatusAdapter.assemble(0)),
          'tick 42': (_) => _labelled('StatusView', StatusAdapter.assemble(42)),
        },
      ),
      CatalogEntry(
        name: 'WorkspaceSwitchView',
        kind: CatalogKind.widget,
        states: {
          'A': (_) => _labelled(
                'WorkspaceSwitchView',
                WorkspaceSwitchAdapter.assemble('A', _workspace),
              ),
          'B': (_) => _labelled(
                'WorkspaceSwitchView',
                WorkspaceSwitchAdapter.assemble('B', _workspace),
              ),
        },
      ),
      CatalogEntry(
        name: 'ConfirmDialogView',
        kind: CatalogKind.widget,
        states: {
          'short': (_) => _labelled(
                'ConfirmDialogView',
                ConfirmDialogView(
                  message: 'Delete "Alpha"?',
                  onConfirm: () {},
                  onCancel: () {},
                ),
              ),
          'long': (_) => _labelled(
                'ConfirmDialogView',
                ConfirmDialogView(
                  message:
                      'Delete "A very long note title that wraps onto more than one line"?',
                  onConfirm: () {},
                  onCancel: () {},
                ),
              ),
        },
      ),
      CatalogEntry(
        name: 'RenameDialogView',
        kind: CatalogKind.widget,
        states: {
          'valid': (_) => _labelled(
                'RenameDialogView',
                RenameDialogAdapter.assemble(
                  const RenameFormData(valid: true),
                  _rename,
                  TextEditingController(text: 'Alpha'),
                  onSave: () {},
                  onCancel: () {},
                ),
              ),
          'invalid': (_) => _labelled(
                'RenameDialogView',
                RenameDialogAdapter.assemble(
                  const RenameFormData(valid: false),
                  _rename,
                  TextEditingController(),
                  onSave: () {},
                  onCancel: () {},
                ),
              ),
        },
      ),
      CatalogEntry(
        name: 'HomeView',
        kind: CatalogKind.screen,
        states: {
          'default': (_) => _labelledScreen(
                'HomeView',
                _home(online: true, hasQuery: false),
              ),
          'offline-searching': (_) => _labelledScreen(
                'HomeView',
                _home(online: false, hasQuery: true),
              ),
        },
      ),
      CatalogEntry(
        name: 'StartView',
        kind: CatalogKind.screen,
        states: {
          'empty': (_) => _labelledScreen(
                'StartView',
                FlowStartAdapter.assemble('', _flow, onNext: () {}),
              ),
          'filled': (_) => _labelledScreen(
                'StartView',
                FlowStartAdapter.assemble('Ann', _flow, onNext: () {}),
              ),
        },
      ),
      CatalogEntry(
        name: 'ConfirmView',
        kind: CatalogKind.screen,
        states: {
          'short name': (_) => _labelledScreen(
                'ConfirmView',
                FlowConfirmAdapter.assemble('Ann', onBack: () {}),
              ),
          'long name': (_) => _labelledScreen(
                'ConfirmView',
                FlowConfirmAdapter.assemble(
                  'Maximilian Alexander the Third',
                  onBack: () {},
                ),
              ),
        },
      ),
    ];

Widget catalogApp() => MaterialApp(
      home: CatalogPage(
        entries: catalogEntries(),
        themeBuilder: (tokens, brightness) => ThemeData(
          colorSchemeSeed: tokens.seed,
          brightness: brightness,
          fontFamily: tokens.fontFamily,
        ),
      ),
    );

void main() => runApp(catalogApp());
