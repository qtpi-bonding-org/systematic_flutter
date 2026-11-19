import 'package:flutter/material.dart';

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
              child: const Text('Start flow'),
            ),
          ],
        ),
      ),
    );
  }
}
