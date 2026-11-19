import 'package:flutter/material.dart';

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
      title: const Text('Rename note'),
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
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('rename-save'),
          onPressed: data.valid ? onSave : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
