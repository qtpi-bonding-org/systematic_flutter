import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

class TabStripView extends StatelessWidget {
  const TabStripView({
    super.key,
    required this.tabs,
    required this.active,
    required this.onSelect,
    required this.onClose,
    required this.body,
  });

  final List<({String id, Label label})> tabs;
  final String active;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          children: [
            for (final tab in tabs)
              ...[
                TextButton(
                  key: ValueKey('tab-${tab.id}'),
                  onPressed: () => onSelect(tab.id),
                  style: tab.id == active
                      ? TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        )
                      : null,
                  child: Text(context.resolveLabel(tab.label)),
                ),
                IconButton(
                  key: ValueKey('close-tab-${tab.id}'),
                  onPressed: () => onClose(tab.id),
                  iconSize: 16,
                  icon: const Icon(Icons.close),
                ),
              ],
          ],
        ),
        body,
      ],
    );
  }
}
