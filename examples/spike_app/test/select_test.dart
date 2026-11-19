import 'package:flutter_test/flutter_test.dart';
import 'package:spike_app/notes/notes_cubit.dart';
import 'package:spike_app/rename/rename_form_cubit.dart';
import 'package:spike_app/search/search_cubit.dart';
import 'package:spike_app/status/status_cubit.dart';
import 'package:spike_app/tabs/tabs_cubit.dart';

const a = Note(id: 'a', title: 'Alpha', tag: 'tag1');
const b = Note(id: 'b', title: 'Beta', tag: 'tag2');

void main() {
  test('selectNoteIds returns the ids in order and ignores other fields', () {
    const s1 = NotesState(notes: [a, b]);
    const s2 = NotesState(
        notes: [Note(id: 'a', title: 'Changed', tag: 'tag3'), b]);
    expect(selectNoteIds(s1).ids, ['a', 'b']);
    expect(selectNoteIds(s1), selectNoteIds(s2));
    expect(selectNoteIds(s1).hashCode, selectNoteIds(s2).hashCode);
    expect(selectNoteIds(const NotesState(notes: [b, a])),
        isNot(selectNoteIds(s1)));
  });

  test('selectNote returns one note, selection flag, and null when missing', () {
    const s = NotesState(notes: [a, b], selectedId: 'b');
    expect(selectNote(s, 'a'),
        const NoteTileData(id: 'a', title: 'Alpha', tag: 'tag1', selected: false));
    expect(selectNote(s, 'b')!.selected, isTrue);
    expect(selectNote(s, 'zzz'), isNull);
  });

  test('selectNote is equal for an untouched note when another note changes', () {
    const s1 = NotesState(notes: [a, b]);
    final s2 = NotesState(
        notes: [a, b.copyWith(title: 'Beta2')]);
    expect(selectNote(s1, 'a'), selectNote(s2, 'a'));
    expect(selectNote(s1, 'b'), isNot(selectNote(s2, 'b')));
  });

  test('selectSearchPanel: hasQuery flips on empty/non-empty, ignores ticks', () {
    expect(selectSearchPanel(const SearchState(query: ''),
        const StatusState(tick: 0, online: true)).hasQuery, isFalse);
    final x = selectSearchPanel(const SearchState(query: 'a'),
        const StatusState(tick: 0, online: true));
    final y = selectSearchPanel(const SearchState(query: 'abc'),
        const StatusState(tick: 9, online: true));
    expect(x.hasQuery, isTrue);
    expect(x, y);
    expect(
        selectSearchPanel(const SearchState(query: 'a'),
            const StatusState(tick: 0, online: false)),
        isNot(x));
  });

  test('selectTick returns the tick', () {
    expect(selectTick(const StatusState(tick: 3, online: true)), 3);
  });

  test('selectRenameForm is valid only for non-blank text', () {
    expect(selectRenameForm(const RenameFormState(text: '  ')).valid, isFalse);
    expect(selectRenameForm(const RenameFormState(text: 'x')).valid, isTrue);
    expect(selectRenameForm(const RenameFormState(text: 'x')),
        selectRenameForm(const RenameFormState(text: 'xyz')));
  });

  test('TabsCubit selects a tab; selectTabStrip lists both tabs', () async {
    final c = TabsCubit();
    expect(c.state, 'tab1');
    c.select('tab2');
    expect(c.state, 'tab2');
    final d = selectTabStrip('tab2');
    expect(d.active, 'tab2');
    expect(d.tabs.map((x) => x.id), ['tab1', 'tab2']);
    expect(selectTabStrip('tab1'), isNot(d));
    await c.close();
  });
}
