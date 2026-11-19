import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

import '../l10n/l10n_key_resolver.g.dart';

class TabStripView extends StatelessWidget {
  const TabStripView({
    super.key,
    required this.tabs,
    required this.active,
    required this.canClose,
    required this.onSelect,
    required this.onClose,
    required this.onNew,
    required this.body,
  });

  final List<({String id, Label label})> tabs;
  final String active;
  final bool canClose;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final VoidCallback onNew;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Takes the height its parent gives it (a screen region). The body gets
    // what the strip leaves and scrolls or clips within it.
    return Column(
      children: [
        // One row that scrolls sideways: at 2x text and 320 width the tabs
        // never grow the strip taller, so the body keeps its space.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
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
                  if (canClose)
                    IconButton(
                      key: ValueKey('close-tab-${tab.id}'),
                      onPressed: () => onClose(tab.id),
                      iconSize: 16,
                      icon: const Icon(Icons.close),
                    ),
                ],
              IconButton(
                key: const ValueKey('new-tab'),
                onPressed: onNew,
                tooltip: context.resolveLabel(L10nKeys.tabNew),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
