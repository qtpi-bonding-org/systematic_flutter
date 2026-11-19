import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_app/notes/notes_source.dart';
import 'package:spike_app/notes/notes_cubit.dart';
import 'package:systematic_failure/systematic_failure.dart';

import 'helpers.dart';

void main() {
  useErrorCapture();

  testWidgets('notes show a loading state, then the notes', (t) async {
    final source = GatedNotesSource();
    await pumpApp(t, notesSource: source);
    expect(find.text('Loading notes'), findsOneWidget);
    expect(find.text('A tab1 note 1'), findsNothing);
    expect(notes(t, 'tab1').state.isLoading, isTrue);

    source.pending.first.complete(seedNotes('A', 'tab1'));
    await settle(t);
    expect(find.text('Loading notes'), findsNothing);
    expect(find.text('A tab1 note 1'), findsOneWidget);
    expect(notes(t, 'tab1').state.isSuccess, isTrue);
    await unmountApp(t);
  });

  testWidgets('an empty notes list shows the empty label', (t) async {
    final source = GatedNotesSource();
    await pumpApp(t, notesSource: source);
    source.pending.first.complete(const []);
    await settle(t);
    expect(find.text('No notes yet'), findsOneWidget);
    await unmountApp(t);
  });

  testWidgets('a domain failure shows its own message and is captured',
      (t) async {
    final source = FlakyNotesSource(const NotesUnavailable());
    await pumpApp(t, notesSource: source);
    await settle(t);
    // Inline in the list and as a toast.
    expect(find.text('Notes are unavailable right now'), findsWidgets);
    expect(find.text('Retry'), findsOneWidget);
    expect(await capturedErrors(), 1);
    final entry = (await ErrorPrivserver.getUnsentErrors()).single.errorData;
    expect(entry.bin, Bin.environment);
    await unmountApp(t);
  });

  testWidgets('a bug shows the generic message', (t) async {
    final source = FlakyNotesSource(StateError('boom'));
    await pumpApp(t, notesSource: source);
    await settle(t);
    expect(find.text('Something went wrong'), findsWidgets);
    expect(find.text('boom'), findsNothing);
    final entry = (await ErrorPrivserver.getUnsentErrors()).single.errorData;
    expect(entry.bin, Bin.bug);
    await unmountApp(t);
  });

  testWidgets('retry loads again and shows the notes', (t) async {
    final source = FlakyNotesSource(const NotesUnavailable());
    await pumpApp(t, notesSource: source);
    await settle(t);
    source.fail = false;
    await t.tap(find.text('Retry'));
    await settle(t);
    expect(source.calls, 2);
    expect(find.text('A tab1 note 1'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    await unmountApp(t);
  });

  test('selectNoteIds maps status to the union variants', () {
    expect(selectNoteIds(const NotesState()), isA<NoteListLoading>());
    expect(selectNoteIds(const NotesState(status: UiFlowStatus.loading)),
        isA<NoteListLoading>());
    final failed = selectNoteIds(NotesState(
      status: UiFlowStatus.failure,
      error: const NotesUnavailable(),
    ));
    expect(failed, isA<NoteListFailed>());
    expect((failed as NoteListFailed).message, const NotesUnavailable().message);
    final bug = selectNoteIds(NotesState(
      status: UiFlowStatus.failure,
      error: StateError('x'),
    )) as NoteListFailed;
    expect(bug.message, isNot(failed.message));
    expect(
      selectNoteIds(const NotesState(
        status: UiFlowStatus.success,
        notes: [Note(id: 'a', title: 'A', tag: 't')],
      )),
      isA<NoteListLoaded>(),
    );
  });
}
