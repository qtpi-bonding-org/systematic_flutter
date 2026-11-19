import '../notes/notes_cubit.dart';
import '../notes/notes_source.dart';

class InMemoryNotesSource implements NotesSource {
  const InMemoryNotesSource();

  @override
  Future<List<Note>> load(String workspaceId, String tabId) async =>
      seedNotes(workspaceId, tabId);
}
