import 'package:flutter/material.dart';

class ConfirmDialogView extends StatelessWidget {
  const ConfirmDialogView({
    super.key,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  });

  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          key: const ValueKey('confirm-no'),
          onPressed: onCancel,
          child: const Text('No'),
        ),
        TextButton(
          key: const ValueKey('confirm-yes'),
          onPressed: onConfirm,
          child: const Text('Yes'),
        ),
      ],
    );
  }
}
