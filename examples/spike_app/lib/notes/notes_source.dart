import 'package:l10n_key_resolver/runtime.dart';
import 'package:systematic_failure/systematic_failure.dart';

import '../l10n/l10n_key_resolver.g.dart';
import 'notes_cubit.dart';

/// Where a tab's notes come from. A real app would call a server or a
/// database here; the spike keeps everything in memory.
abstract class NotesSource {
  Future<List<Note>> load(String workspaceId, String tabId);
}

/// The notes service is down. An environment failure: captured as such and
/// shown with its own message.
class NotesUnavailable extends EnvironmentException {
  const NotesUnavailable();

  @override
  L10nKey? get message => L10nKeys.notesUnavailable;
}
