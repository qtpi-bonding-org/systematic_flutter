import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_app/catalog_main.dart';
import 'package:spike_app/scopes.dart';
import 'package:spike_app/flow/flow_cubit.dart';
import 'package:spike_app/notes/notes_cubit.dart';
import 'package:spike_app/rename/rename_form_cubit.dart';
import 'package:spike_app/search/search_cubit.dart';
import 'package:spike_app/status/status_cubit.dart';
import 'package:spike_app/tabs/tabs_cubit.dart';
import 'package:spike_app/views/confirm_dialog_view.dart';
import 'package:spike_app/views/tag_chip.dart';
import 'package:spike_app/views/workspace_switch_view.dart';
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

  test('every entry shows exactly the states of its ViewData.samples()', () {
    final fromSamples = <String, Iterable<String>>{
      'TagChip': TagChipData.samples().keys,
      'NoteTile': NoteTileData.samples().keys,
      'NoteListView': NoteListData.samples().keys,
      'TabStripView': TabStripData.samples().keys,
      'SearchPanelView': SearchPanelData.samples().keys,
      'StatusView': StatusData.samples().keys,
      'WorkspaceSwitchView': WorkspaceSwitchData.samples().keys,
      'ConfirmDialogView': ConfirmDialogData.samples().keys,
      'RenameDialogView': RenameFormData.samples().keys,
      'StartView': FlowNameData.samples().keys,
      'ConfirmView': FlowNameData.samples().keys,
    };
    final entries = {for (final e in catalogEntries()) e.name: e};
    for (final e in fromSamples.entries) {
      expect(entries[e.key]!.states.keys.toList(), e.value.toList(),
          reason: e.key);
    }
  });

  testWidgets('the catalog shows loading and error states of the list',
      (t) async {
    t.view.physicalSize = const Size(2400, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(catalogApp());
    await t.pump();
    expect(find.text('NoteListView / loading'), findsOneWidget);
    expect(find.text('NoteListView / error'), findsOneWidget);
    expect(find.text('Loading notes'), findsNWidgets(2));
    expect(find.text('Notes are unavailable right now'), findsNWidgets(2));
    expect(find.text('No notes yet'), findsNWidgets(2));
  });

  testWidgets('the spacing control changes a real widget\'s padding',
      (t) async {
    t.view.physicalSize = const Size(2400, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(catalogApp());
    await t.pump();
    final pad = find.byKey(const ValueKey('tile-pad-a')).first;
    final before = t.widget<Padding>(pad).padding as EdgeInsets;
    final r = t.getRect(find.byKey(const Key('catalog.spacingScale')));
    await t.tapAt(Offset(r.right - 1, r.center.dy));
    await t.pump();
    final after =
        t.widget<Padding>(find.byKey(const ValueKey('tile-pad-a')).first)
            .padding as EdgeInsets;
    expect(after.left, greaterThan(before.left * 1.4));
  });

  testWidgets('the size control changes a real widget\'s corner radius',
      (t) async {
    t.view.physicalSize = const Size(2400, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(catalogApp());
    await t.pump();
    double radius() {
      final ink = t.widget<InkWell>(find.descendant(
          of: find.byType(TagChip).first, matching: find.byType(InkWell)));
      return ink.borderRadius!.resolve(TextDirection.ltr).topLeft.x;
    }

    final before = radius();
    final r = t.getRect(find.byKey(const Key('catalog.sizeScale')));
    await t.tapAt(Offset(r.right - 1, r.center.dy));
    await t.pump();
    expect(radius(), greaterThan(before * 1.4));
  });

  testWidgets('the colour control edits palette tokens in the real theme',
      (t) async {
    t.view.physicalSize = const Size(2400, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(catalogApp());
    await t.pump();
    Color primary() => Theme.of(t.element(find.byType(TagChip).first))
        .colorScheme
        .primary;
    final before = primary();
    await t.tap(find.byKey(const Key('catalog.color.color1.2')));
    await t.pump();
    expect(primary(), isNot(before));
  });

  testWidgets('every tile survives large text, narrow width and right-to-left',
      (t) async {
    t.view.physicalSize = const Size(2400, 6000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(catalogApp());
    await t.pump();
    for (final k in ['largeText', 'narrow', 'rtl']) {
      await t.tap(find.byKey(Key('catalog.toggle.$k')));
      await t.pump();
    }
    expect(find.text('Loading notes'), findsNWidgets(2));
    // Overflow is reported as an exception; text can wrap, so none expected
    // from the narrow tiles beyond what the views handle.
    final e = t.takeException();
    expect(e, isNull);
  });
}
