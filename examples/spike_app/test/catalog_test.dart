import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_app/catalog_main.dart';
import 'package:spike_app/scopes.dart';
import 'package:systematic_catalog/systematic_catalog.dart';

const expected = {
  'TagChip': CatalogKind.widget,
  'NoteTile': CatalogKind.widget,
  'NoteListView': CatalogKind.widget,
  'TabStripView': CatalogKind.widget,
  'SearchPanelView': CatalogKind.widget,
  'StatusView': CatalogKind.widget,
  'WorkspaceSwitchView': CatalogKind.widget,
  'ConfirmDialogView': CatalogKind.widget,
  'RenameDialogView': CatalogKind.widget,
  'HomeView': CatalogKind.screen,
  'StartView': CatalogKind.screen,
  'ConfirmView': CatalogKind.screen,
};

void main() {
  test('catalog lists every view with the right kind', () {
    final entries = catalogEntries();
    expect({for (final e in entries) e.name: e.kind}, expected);
    for (final e in entries) {
      expect(e.states, isNotEmpty, reason: e.name);
    }
  });

  testWidgets('catalog page renders every entry with no scopes or cubits',
      (t) async {
    t.view.physicalSize = const Size(1600, 4000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(catalogApp());
    await t.pump();
    for (final name in expected.keys) {
      expect(find.text(name), findsWidgets, reason: name);
    }
    expect(find.byType(ScopeProvider<SessionScope>), findsNothing);
    expect(find.byType(ScopeProvider<WorkspaceScope>), findsNothing);
    expect(find.byType(ScopeProvider<FlowScope>), findsNothing);
    expect(find.byType(BlocProvider<Cubit<Object?>>), findsNothing);
    expect(t.takeException(), isNull);
  });
}
