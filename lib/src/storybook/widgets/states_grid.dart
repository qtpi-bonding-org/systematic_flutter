// lib/src/storybook/widgets/states_grid.dart
import 'package:flutter/material.dart';

/// Renders one widget per named state in a wrapping row of labeled cells.
/// Plain Flutter — does NOT use UiScaler (it is chrome, not stage content).
class StatesGrid extends StatelessWidget {
  const StatesGrid({super.key, required this.states});

  final Map<String, WidgetBuilder> states;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        for (final entry in states.entries)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Builder(builder: entry.value),
            ],
          ),
      ],
    );
  }
}
