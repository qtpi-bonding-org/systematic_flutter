import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_app/adapters/notes_message_mapper.dart';
import 'package:spike_app/l10n/l10n_key_resolver.g.dart';
import 'package:spike_app/notes/notes_cubit.dart';

import 'helpers.dart';

void main() {
  useErrorCapture();

  testWidgets('renaming a note shows a toast through the listener',
      (t) async {
    await pumpApp(t);
    expect(find.byType(SnackBar), findsNothing);
    await t.tap(key('rename-tab1-1'));
    await t.pumpAndSettle();
    await t.enterText(key('rename-field'), 'Fresh title');
    await settle(t);
    await t.tap(key('rename-save'));
    await t.pumpAndSettle();
    expect(find.text('Fresh title'), findsOneWidget);
    expect(find.text('Note renamed'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    await unmountApp(t);
  });

  testWidgets('deleting a note shows a toast', (t) async {
    await pumpApp(t);
    await t.tap(key('delete-tab1-2'));
    await t.pumpAndSettle();
    await t.tap(key('confirm-yes'));
    await t.pumpAndSettle();
    expect(find.text('Note deleted'), findsOneWidget);
    await unmountApp(t);
  });

  testWidgets('selecting a note shows no toast', (t) async {
    await pumpApp(t);
    await t.tap(key('tile-tab1-1'));
    await settle(t);
    expect(find.byType(SnackBar), findsNothing);
    await unmountApp(t);
  });

  group('NotesMessageMapper', () {
    final mapper = NotesMessageMapper.create();

    test('maps events to success keys', () {
      expect(
        mapper.map(NotesState(
          status: UiFlowStatus.success,
          event: NotesEvent.renamed(),
        )),
        const MessageKey.success(L10nKeys.noteRenamed),
      );
      expect(
        mapper.map(NotesState(
          status: UiFlowStatus.success,
          event: NotesEvent.deleted(),
        )),
        const MessageKey.success(L10nKeys.noteDeleted),
      );
    });

    test('loaded and idle states map to nothing', () {
      expect(mapper.map(const NotesState()), isNull);
      expect(
        mapper.map(NotesState(
          status: UiFlowStatus.success,
          event: NotesEvent.loaded(),
        )),
        isNull,
      );
    });

    test('an error maps to an error key', () {
      final key = mapper.map(NotesState(
        status: UiFlowStatus.failure,
        error: StateError('x'),
      ));
      expect(key?.type, MessageType.error);
      expect(key?.label, L10nKeys.errorGeneric);
    });
  });
}
