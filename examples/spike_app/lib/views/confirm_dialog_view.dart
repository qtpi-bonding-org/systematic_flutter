import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

import '../l10n/l10n_key_resolver.g.dart';

@immutable
class ConfirmDialogData {
  const ConfirmDialogData({required this.question});

  final Label question;

  static Map<String, ConfirmDialogData> samples() => {
        'short': ConfirmDialogData(
          question: L10nKeys.confirmDeleteNote(title: 'Alpha'),
        ),
        'long': ConfirmDialogData(
          question: L10nKeys.confirmDeleteNote(
            title: 'A very long note title that wraps onto more than one line',
          ),
        ),
      };

  @override
  bool operator ==(Object other) =>
      other is ConfirmDialogData && other.question == question;

  @override
  int get hashCode => question.hashCode;
}

class ConfirmDialogView extends StatelessWidget {
  const ConfirmDialogView({
    super.key,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
  });

  final ConfirmDialogData data;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(context.resolveLabel(data.question)),
      actions: [
        TextButton(
          key: const ValueKey('confirm-no'),
          onPressed: onCancel,
          child: Text(context.resolveLabel(L10nKeys.confirmNo)),
        ),
        TextButton(
          key: const ValueKey('confirm-yes'),
          onPressed: onConfirm,
          child: Text(context.resolveLabel(L10nKeys.confirmYes)),
        ),
      ],
    );
  }
}
