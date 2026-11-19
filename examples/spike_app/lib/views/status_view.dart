import 'package:flutter/material.dart';

class StatusView extends StatelessWidget {
  const StatusView({super.key, required this.tick});

  final int tick;

  @override
  Widget build(BuildContext context) => Text('Tick $tick');
}
