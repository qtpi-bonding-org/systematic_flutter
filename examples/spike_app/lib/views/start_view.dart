import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

import '../flow/flow_cubit.dart';
import '../l10n/l10n_key_resolver.g.dart';

class StartView extends StatelessWidget {
  const StartView({
    super.key,
    required this.data,
    required this.onNameChanged,
    required this.onNext,
  });

  final FlowNameData data;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.resolveLabel(L10nKeys.startTitle))),
      body: Padding(
        padding: context.padding.page,
        child: Column(
          children: [
            TextFormField(
              key: const ValueKey('name-field'),
              initialValue: data.name,
              onChanged: onNameChanged,
              decoration: InputDecoration(
                labelText: context.resolveLabel(L10nKeys.nameLabel),
              ),
            ),
            VSpace.x2,
            ElevatedButton(
              key: const ValueKey('next-button'),
              onPressed: onNext,
              child: Text(context.resolveLabel(L10nKeys.actionNext)),
            ),
          ],
        ),
      ),
    );
  }
}
