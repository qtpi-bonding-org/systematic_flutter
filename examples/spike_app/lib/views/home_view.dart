import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

import '../l10n/l10n_key_resolver.g.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.header,
    required this.tabs,
    required this.search,
    required this.status,
    required this.onStartFlow,
  });

  final Widget header;
  final Widget tabs;
  final Widget search;
  final Widget status;
  final VoidCallback onStartFlow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(child: tabs),
            search,
            status,
            TextButton(
              onPressed: onStartFlow,
              child: Text(context.resolveLabel(L10nKeys.startFlow)),
            ),
          ],
        ),
      ),
    );
  }
}
