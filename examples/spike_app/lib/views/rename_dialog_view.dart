import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

import '../l10n/l10n_key_resolver.g.dart';
import '../rename/rename_form_cubit.dart';

class RenameDialogView extends StatelessWidget {
  const RenameDialogView({
    super.key,
    required this.data,
    required this.controller,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  final RenameFormData data;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.resolveLabel(L10nKeys.noteRenameTitle)),
      content: TextField(
        key: const ValueKey('rename-field'),
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
      ),
      actions: [
        TextButton(
          key: const ValueKey('rename-cancel'),
          onPressed: onCancel,
          child: Text(context.resolveLabel(L10nKeys.actionCancel)),
        ),
        TextButton(
          key: const ValueKey('rename-save'),
          onPressed: data.valid ? onSave : null,
          child: Text(context.resolveLabel(L10nKeys.actionSave)),
        ),
      ],
    );
  }
}
