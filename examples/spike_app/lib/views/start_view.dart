import 'package:flutter/material.dart';

class StartView extends StatelessWidget {
  const StartView({
    super.key,
    required this.name,
    required this.onNameChanged,
    required this.onNext,
  });

  final String name;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              key: const ValueKey('name-field'),
              initialValue: name,
              onChanged: onNameChanged,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const ValueKey('next-button'),
              onPressed: onNext,
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
