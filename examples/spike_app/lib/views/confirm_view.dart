import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

import '../flow/flow_cubit.dart';
import '../l10n/l10n_key_resolver.g.dart';

class ConfirmView extends StatelessWidget {
  const ConfirmView({super.key, required this.data, required this.onBack});

  final FlowNameData data;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.resolveLabel(L10nKeys.reviewTitle))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data.name),
            TextButton(
              key: const ValueKey('back-button'),
              onPressed: onBack,
              child: Text(context.resolveLabel(L10nKeys.actionBack)),
            ),
          ],
        ),
      ),
    );
  }
}
