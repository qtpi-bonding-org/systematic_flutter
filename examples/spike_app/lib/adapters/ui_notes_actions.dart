import 'package:flutter/material.dart';

import '../notes/notes_cubit.dart';
import '../views/confirm_dialog_view.dart';

/// Notes actions backed by a [NotesCubit] and dialogs on [_context].
/// Not a widget: it only translates view callbacks into cubit calls.
class UiNotesActions implements NotesActions {
  UiNotesActions(this._context, this._cubit);

  final BuildContext _context;
  final NotesCubit _cubit;

  @override
  Future<void> select(String id) => _cubit.select(id);

  @override
  Future<void> rename(String id, String title) => _cubit.rename(id, title);

  @override
  void cycleTag(String id) => _cubit.cycleTag(id);

  @override
  Future<void> delete(String id) async {
    final matches = _cubit.state.notes.where((n) => n.id == id);
    final title = matches.isEmpty ? null : matches.first.title;
    if (title == null || !_context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: _context,
      builder: (dc) => ConfirmDialogView(
        message: 'Delete "$title"?',
        onConfirm: () => Navigator.of(dc).pop(true),
        onCancel: () => Navigator.of(dc).pop(false),
      ),
    );
    if (confirmed == true && !_cubit.isClosed) {
      await _cubit.delete(id);
    }
  }

  @override
  Future<void> deleteSelected() {
    final id = _cubit.state.selectedId;
    if (id == null) return Future<void>.value();
    return delete(id);
  }
}
