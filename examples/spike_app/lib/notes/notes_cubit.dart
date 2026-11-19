import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@immutable
class Note {
  const Note({required this.id, required this.title, required this.tag});

  final String id;
  final String title;
  final String tag;

  Note copyWith({String? title, String? tag}) => Note(
        id: id,
        title: title ?? this.title,
        tag: tag ?? this.tag,
      );

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.id == id &&
      other.title == title &&
      other.tag == tag;

  @override
  int get hashCode => Object.hash(id, title, tag);
}

@immutable
class NotesState {
  const NotesState({required this.notes, this.selectedId});

  final List<Note> notes;
  final String? selectedId;

  NotesState copyWith({
    List<Note>? notes,
    String? selectedId,
    bool clearSelection = false,
  }) =>
      NotesState(
        notes: notes ?? this.notes,
        selectedId:
            clearSelection ? null : (selectedId ?? this.selectedId),
      );

  @override
  bool operator ==(Object other) =>
      other is NotesState &&
      listEquals(other.notes, notes) &&
      other.selectedId == selectedId;

  @override
  int get hashCode => Object.hash(Object.hashAll(notes), selectedId);
}

/// The ids of the notes, in order. Equal when the id list is equal.
@immutable
class NoteListData {
  NoteListData(List<String> ids) : ids = List.unmodifiable(ids);

  final List<String> ids;

  @override
  bool operator ==(Object other) =>
      other is NoteListData && listEquals(other.ids, ids);

  @override
  int get hashCode => Object.hashAll(ids);
}

@immutable
class NoteTileData {
  const NoteTileData({
    required this.id,
    required this.title,
    required this.tag,
    required this.selected,
  });

  final String id;
  final String title;
  final String tag;
  final bool selected;

  @override
  bool operator ==(Object other) =>
      other is NoteTileData &&
      other.id == id &&
      other.title == title &&
      other.tag == tag &&
      other.selected == selected;

  @override
  int get hashCode => Object.hash(id, title, tag, selected);
}

NoteListData selectNoteIds(NotesState s) =>
    NoteListData([for (final n in s.notes) n.id]);

NoteTileData? selectNote(NotesState s, String id) {
  for (final n in s.notes) {
    if (n.id == id) {
      return NoteTileData(
        id: n.id,
        title: n.title,
        tag: n.tag,
        selected: s.selectedId == id,
      );
    }
  }
  return null;
}

List<Note> seedNotes(String workspaceId, String tabId) => [
      for (var i = 1; i <= 3; i++)
        Note(
          id: '$tabId-$i',
          title: '$workspaceId $tabId note $i',
          tag: 'tag$i',
        ),
    ];

String _nextTag(String tag) {
  final n = int.tryParse(tag.replaceFirst('tag', '')) ?? 0;
  return 'tag${n % 3 + 1}';
}

abstract class NotesActions {
  Future<void> select(String id);
  Future<void> delete(String id);
  Future<void> deleteSelected();
  Future<void> rename(String id, String title);
  void cycleTag(String id);
}

class NotesCubit extends Cubit<NotesState> implements NotesActions {
  NotesCubit(List<Note> initial)
      : super(NotesState(notes: List.unmodifiable(initial)));

  bool _has(String id) => state.notes.any((n) => n.id == id);

  @override
  Future<void> select(String id) async {
    if (!_has(id)) return;
    emit(state.copyWith(selectedId: id));
  }

  @override
  Future<void> delete(String id) async {
    if (!_has(id)) return;
    emit(NotesState(
      notes: [
        for (final n in state.notes)
          if (n.id != id) n,
      ],
      selectedId: state.selectedId == id ? null : state.selectedId,
    ));
  }

  @override
  Future<void> deleteSelected() async {
    final id = state.selectedId;
    if (id == null) return;
    await delete(id);
  }

  @override
  Future<void> rename(String id, String title) async {
    if (!_has(id)) return;
    emit(state.copyWith(
      notes: [
        for (final n in state.notes) n.id == id ? n.copyWith(title: title) : n,
      ],
    ));
  }

  @override
  void cycleTag(String id) {
    if (!_has(id)) return;
    emit(state.copyWith(
      notes: [
        for (final n in state.notes)
          n.id == id ? n.copyWith(tag: _nextTag(n.tag)) : n,
      ],
    ));
  }
}
