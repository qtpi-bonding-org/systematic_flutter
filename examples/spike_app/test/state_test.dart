import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spike_app/flow/flow_cubit.dart';
import 'package:spike_app/scopes.dart';
import 'package:spike_app/views/confirm_view.dart';
import 'package:spike_app/views/start_view.dart';

import 'helpers.dart';

void main() {
  testWidgets('the app shows the seeded notes of the first tab', (t) async {
    await pumpApp(t);
    expect(find.text('A tab1 note 1'), findsOneWidget);
    expect(find.text('A tab1 note 3'), findsOneWidget);
    expect(find.text('A tab2 note 1'), findsNothing);
    await unmountApp(t);
  });

  testWidgets('workspace switch keeps the search query, replaces notes cubits',
      (t) async {
    await pumpApp(t);
    final s = session(t);
    final oldNotes = notes(t, 'tab1');
    await t.enterText(key('search-field'), 'hello');
    await settle(t);
    expect(s.search.state.query, 'hello');

    await t.tap(key('ws-B'));
    await settle(t);

    expect(workspace(t).id, 'B');
    expect(identical(session(t), s), isTrue);
    expect(s.search.state.query, 'hello');
    expect(find.widgetWithText(TextField, 'hello'), findsOneWidget);
    expect(find.text('B tab1 note 1'), findsOneWidget);
    expect(find.text('A tab1 note 1'), findsNothing);
    expect(oldNotes.isClosed, isTrue);
    expect(identical(notes(t, 'tab1'), oldNotes), isFalse);
    await unmountApp(t);
  });

  testWidgets('two tabs are independent and kept across a tab switch',
      (t) async {
    await pumpApp(t);
    final tab1 = notes(t, 'tab1');
    await tab1.delete('tab1-1');
    await settle(t);
    expect(find.text('A tab1 note 1'), findsNothing);

    await t.tap(key('tab-tab2'));
    await settle(t);
    expect(find.text('A tab2 note 1'), findsOneWidget);
    expect(find.text('A tab1 note 2'), findsNothing);
    final tab2 = notes(t, 'tab2');
    expect(identical(tab1, tab2), isFalse);
    await tab2.rename('tab2-1', 'Renamed in two');
    await settle(t);

    await t.tap(key('tab-tab1'));
    await settle(t);
    expect(identical(notes(t, 'tab1'), tab1), isTrue);
    expect(tab1.isClosed, isFalse);
    expect(find.text('A tab1 note 1'), findsNothing);
    expect(find.text('A tab1 note 2'), findsOneWidget);

    await t.tap(key('tab-tab2'));
    await settle(t);
    expect(find.text('Renamed in two'), findsOneWidget);
    expect(find.text('A tab2 note 2'), findsOneWidget);
    await unmountApp(t);
  });

  testWidgets('both flow steps see the same cubit instance', (t) async {
    await pumpApp(t, initialLocation: '/start');
    final startScope =
        ScopeProvider.of<FlowScope>(t.element(find.byType(StartView)));
    final flow = startScope.flow;
    await t.enterText(key('name-field'), 'Ann');
    await settle(t);
    expect(flow.state.name, 'Ann');

    await t.tap(key('next-button'));
    await t.pumpAndSettle();

    expect(find.byType(ConfirmView), findsOneWidget);
    final confirmScope =
        ScopeProvider.of<FlowScope>(t.element(find.byType(ConfirmView)));
    expect(identical(confirmScope, startScope), isTrue);
    expect(identical(confirmScope.flow, flow), isTrue);
    expect(find.text('Ann'), findsOneWidget);
    await unmountApp(t);
  });

  testWidgets('flow scope is disposed when the flow is left', (t) async {
    await pumpApp(t, initialLocation: '/start');
    final flow = ScopeProvider.of<FlowScope>(t.element(find.byType(StartView)))
        .flow;
    GoRouter.of(t.element(find.byType(StartView))).go('/');
    await t.pumpAndSettle();
    expect(flow.isClosed, isTrue);
    await unmountApp(t);
  });

  testWidgets('rename dialog cubit is closed when the dialog closes',
      (t) async {
    await pumpApp(t);
    final s = session(t);
    expect(s.issuedRenameForms, isEmpty);
    await t.tap(key('rename-tab1-1'));
    await t.pumpAndSettle();
    expect(s.issuedRenameForms, hasLength(1));
    final form = s.issuedRenameForms.single;
    expect(form.isClosed, isFalse);

    await t.enterText(key('rename-field'), 'Fresh title');
    await settle(t);
    await t.tap(key('rename-save'));
    await t.pumpAndSettle();

    expect(form.isClosed, isTrue);
    expect(find.text('Fresh title'), findsOneWidget);

    await t.tap(key('rename-tab1-2'));
    await t.pumpAndSettle();
    final second = s.issuedRenameForms.last;
    expect(identical(second, form), isFalse);
    await t.tap(key('rename-cancel'));
    await t.pumpAndSettle();
    expect(second.isClosed, isTrue);
    expect(find.text('A tab1 note 2'), findsOneWidget);
    await unmountApp(t);
  });

  testWidgets('delete asks for confirmation; no keeps, yes deletes', (t) async {
    await pumpApp(t);
    await t.tap(key('delete-tab1-2'));
    await t.pumpAndSettle();
    expect(key('confirm-yes'), findsOneWidget);
    await t.tap(key('confirm-no'));
    await t.pumpAndSettle();
    expect(find.text('A tab1 note 2'), findsOneWidget);

    await t.tap(key('delete-tab1-2'));
    await t.pumpAndSettle();
    await t.tap(key('confirm-yes'));
    await t.pumpAndSettle();
    expect(find.text('A tab1 note 2'), findsNothing);
    expect(notes(t, 'tab1').state.notes.length, 2);
    await unmountApp(t);
  });

  testWidgets('Ctrl+Backspace deletes the selected note after confirmation',
      (t) async {
    await pumpApp(t);
    await t.tap(key('tile-tab1-3'));
    await settle(t);
    expect(notes(t, 'tab1').state.selectedId, 'tab1-3');

    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.backspace);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    expect(key('confirm-yes'), findsOneWidget);
    await t.tap(key('confirm-yes'));
    await t.pumpAndSettle();
    expect(find.text('A tab1 note 3'), findsNothing);
    expect(find.text('A tab1 note 2'), findsOneWidget);
    await unmountApp(t);
  });

  testWidgets('Ctrl+Backspace with nothing selected does nothing', (t) async {
    await pumpApp(t);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.backspace);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    expect(key('confirm-yes'), findsNothing);
    await unmountApp(t);
  });

  testWidgets('the search field text survives a rebuild of the panel',
      (t) async {
    await pumpApp(t);
    await t.enterText(key('search-field'), 'abc');
    await settle(t);
    await session(t).status.setOnline(false);
    await settle(t);
    expect(find.widgetWithText(TextField, 'abc'), findsOneWidget);
    await unmountApp(t);
  });

  test('FlowCubit holds the name', () async {
    final c = FlowCubit();
    c.setName('x');
    expect(c.state.name, 'x');
    await c.close();
  });
}
