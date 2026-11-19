import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:systematic_failure/systematic_failure.dart';

import 'notes_source.dart';
import '../l10n/l10n_key_resolver.g.dart';

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

/// What the last successful operation did. Compared by identity: every
/// factory call is a new event, so the same operation twice still shows
/// its message twice.
enum NotesEventKind { loaded, renamed, deleted }

class NotesEvent {
  NotesEvent._(this.kind);

  factory NotesEvent.loaded() => NotesEvent._(NotesEventKind.loaded);
  factory NotesEvent.renamed() => NotesEvent._(NotesEventKind.renamed);
  factory NotesEvent.deleted() => NotesEvent._(NotesEventKind.deleted);

  final NotesEventKind kind;
}

@immutable
class NotesState with UiFlowStateMixin implements IUiFlowState {
  const NotesState({
    this.status = UiFlowStatus.idle,
    this.notes = const [],
    this.selectedId,
    this.error,
    this.event,
  });

  @override
  final UiFlowStatus status;
  final List<Note> notes;
  final String? selectedId;
  @override
  final Object? error;
  final NotesEvent? event;

  NotesState copyWith({
    UiFlowStatus? status,
    List<Note>? notes,
    String? selectedId,
    bool clearSelection = false,
    Object? error,
    bool clearError = false,
    NotesEvent? event,
  }) =>
      NotesState(
        status: status ?? this.status,
        notes: notes ?? this.notes,
        selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
        error: clearError ? null : (error ?? this.error),
        event: event ?? this.event,
      );

  @override
  NotesState withLoading() =>
      copyWith(status: UiFlowStatus.loading, clearError: true);

  @override
  NotesState withError(Object error) =>
      copyWith(status: UiFlowStatus.failure, error: error);

  @override
  bool operator ==(Object other) =>
      other is NotesState &&
      other.status == status &&
      listEquals(other.notes, notes) &&
      other.selectedId == selectedId &&
      other.error == error &&
      identical(other.event, event);

  @override
  int get hashCode => Object.hash(
        status,
        Object.hashAll(notes),
        selectedId,
        error,
        identityHashCode(event),
      );
}

/// What the note list shows. Sealed, so a view must handle every variant.
sealed class NoteListData {
  const NoteListData();

  /// The ids in order. Only a loaded list has any.
  List<String> get ids => const [];

  static Map<String, NoteListData> samples() => {
        'loading': const NoteListLoading(),
        'error': NoteListFailed(message: L10nKeys.notesUnavailable),
        'empty': NoteListLoaded(const []),
        'full': NoteListLoaded(const ['a', 'b', 'c']),
      };
}

final class NoteListLoading extends NoteListData {
  const NoteListLoading();

  @override
  bool operator ==(Object other) => other is NoteListLoading;

  @override
  int get hashCode => 1;
}

final class NoteListFailed extends NoteListData {
  const NoteListFailed({required this.message});

  final L10nKey message;

  @override
  bool operator ==(Object other) =>
      other is NoteListFailed && other.message == message;

  @override
  int get hashCode => message.hashCode;
}

final class NoteListLoaded extends NoteListData {
  NoteListLoaded(List<String> ids) : ids = List.unmodifiable(ids);

  @override
  final List<String> ids;

  @override
  bool operator ==(Object other) =>
      other is NoteListLoaded && listEquals(other.ids, ids);

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

  static Map<String, NoteTileData> samples() => const {
        'default': NoteTileData(
          id: 'a',
          title: 'Alpha',
          tag: 'tag1',
          selected: false,
        ),
        'selected': NoteTileData(
          id: 'a',
          title: 'Alpha',
          tag: 'tag1',
          selected: true,
        ),
        'long title': NoteTileData(
          id: 'a',
          title:
              'A very long note title that wraps onto more than one line',
          tag: 'tag1',
          selected: false,
        ),
      };

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

/// Maps the notes state to the list view data.
///
/// A list with no notes yet and an idle or loading status is still loading.
/// A failure shows the domain's message, or the generic one for a bug.
NoteListData selectNoteIds(NotesState s) {
  final status = s.status;
  if (status.isFailure) {
    final e = s.error;
    final message = e == null ? null : classify(e).message;
    return NoteListFailed(message: message ?? L10nKeys.errorGeneric);
  }
  if (status.isLoading || (status.isIdle && s.notes.isEmpty)) {
    return const NoteListLoading();
  }
  return NoteListLoaded([for (final n in s.notes) n.id]);
}

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
  Future<void> rename(String id, String title);
  void cycleTag(String id);
  Future<void> reload();
}

/// The notes of one tab. Loads from [NotesSource]; failures are captured by
/// the error inbox and shown by the list and as a toast.
class NotesCubit extends TryOperationCubit<NotesState>
    with ErrorPrivserverMixin<NotesState>
    implements NotesActions {
  NotesCubit(this._source, this._workspaceId, this._tabId)
      : super(const NotesState());

  final NotesSource _source;
  final String _workspaceId;
  final String _tabId;

  bool _has(String id) => state.notes.any((n) => n.id == id);

  /// Loads the tab. Shows the loading state first, then the notes or the
  /// failure.
  Future<void> load() => tryOperation(() async {
        final notes = await _source.load(_workspaceId, _tabId);
        return state.copyWith(
          status: UiFlowStatus.success,
          notes: notes,
          clearError: true,
          event: NotesEvent.loaded(),
        );
      }, emitLoading: true);

  @override
  Future<void> reload() => load();

  @override
  Future<void> select(String id) async {
    if (!_has(id)) return;
    emit(state.copyWith(selectedId: id));
  }

  Future<void> delete(String id) => tryOperation(() {
        if (!_has(id)) return state;
        return state.copyWith(
          status: UiFlowStatus.success,
          notes: [
            for (final n in state.notes)
              if (n.id != id) n,
          ],
          selectedId: state.selectedId == id ? null : state.selectedId,
          clearError: true,
          event: NotesEvent.deleted(),
        );
      });

  Future<void> deleteSelected() async {
    final id = state.selectedId;
    if (id == null) return;
    await delete(id);
  }

  @override
  Future<void> rename(String id, String title) => tryOperation(() {
        if (!_has(id)) return state;
        return state.copyWith(
          status: UiFlowStatus.success,
          notes: [
            for (final n in state.notes)
              n.id == id ? n.copyWith(title: title) : n,
          ],
          clearError: true,
          event: NotesEvent.renamed(),
        );
      });

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
