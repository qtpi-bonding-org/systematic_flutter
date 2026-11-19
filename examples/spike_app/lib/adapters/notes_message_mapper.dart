import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../l10n/l10n_key_resolver.g.dart';
import '../notes/notes_cubit.dart';

/// Turns notes state into toast keys: success for a rename or delete, the
/// classified error otherwise. A load shows nothing (the list shows it).
class NotesMessageMapper {
  NotesMessageMapper._();

  static IStateMessageMapper<NotesState> create() =>
      BaseStateMessageMapper<NotesState>(
        exceptionMapper: ClassifyingExceptionKeyMapper(
          generic: L10nKeys.errorGeneric,
        ),
        domainMapper: _NotesDomainMapper(),
      );
}

class _NotesDomainMapper implements IDomainStateKeyMapper<NotesState> {
  @override
  MessageKey? map(NotesState state) {
    if (!state.status.isSuccess) return null;
    return switch (state.lastOperation) {
      NotesOperation.rename => const MessageKey.success(L10nKeys.noteRenamed),
      NotesOperation.delete => const MessageKey.success(L10nKeys.noteDeleted),
      NotesOperation.load || null => null,
    };
  }
}
