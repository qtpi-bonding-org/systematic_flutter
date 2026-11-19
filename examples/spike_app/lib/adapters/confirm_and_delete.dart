import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../notes/notes_cubit.dart';
import '../views/confirm_dialog_view.dart';

/// Asks the user to confirm, then deletes note [id] through [cubit].
/// Does nothing if the note is gone or the user cancels.
@adapterHelper
Future<void> confirmAndDelete(
  BuildContext context,
  NotesCubit cubit,
  String id,
) async {
  final matches = cubit.state.notes.where((n) => n.id == id);
  final title = matches.isEmpty ? null : matches.first.title;
  if (title == null || !context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dc) => ConfirmDialogView(
      message: 'Delete "$title"?',
      onConfirm: () => Navigator.of(dc).pop(true),
      onCancel: () => Navigator.of(dc).pop(false),
    ),
  );
  if (confirmed == true && !cubit.isClosed) {
    await cubit.delete(id);
  }
}
