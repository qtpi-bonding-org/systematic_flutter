import 'package:flutter/material.dart';

class TabStripView extends StatelessWidget {
  const TabStripView({
    super.key,
    required this.tabs,
    required this.active,
    required this.onSelect,
    required this.body,
  });

  final List<({String id, String label})> tabs;
  final String active;
  final ValueChanged<String> onSelect;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final tab in tabs)
              TextButton(
                key: ValueKey('tab-${tab.id}'),
                onPressed: () => onSelect(tab.id),
                style: tab.id == active
                    ? TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      )
                    : null,
                child: Text(tab.label),
              ),
          ],
        ),
        body,
      ],
    );
  }
}
