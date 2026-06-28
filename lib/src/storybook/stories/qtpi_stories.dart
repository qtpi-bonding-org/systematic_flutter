import 'package:flutter/material.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import '../story.dart';

/// qtpi_ui's own catalog: tokens + the Ds* structure primitives. App-agnostic;
/// [tokens] is the live palette map so the colors gallery re-renders on edits.
List<Story> qtpiStories(Map<String, Color> tokens) => [
      Story(
        category: 'qtpi_ui / Tokens',
        name: 'Colors',
        builder: (context) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in tokens.entries)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: entry.value,
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.key, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
          ],
        ),
      ),
      Story(
        category: 'qtpi_ui / Tokens',
        name: 'Spacing',
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final spec in [
              ('spaceHalf', AppSizes.spaceHalf),
              ('space', AppSizes.space),
              ('radiusMedium', AppSizes.radiusMedium),
              ('buttonHeight', AppSizes.buttonHeight),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(spec.$1)),
                    Container(
                        width: spec.$2,
                        height: 16,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(spec.$2.toStringAsFixed(1)),
                  ],
                ),
              ),
          ],
        ),
      ),
      Story(
        category: 'qtpi_ui / Tokens',
        name: 'Typography',
        builder: (context) {
          final theme = Theme.of(context);
          final styles = <(String, TextStyle?)>[
            ('displayLarge', theme.textTheme.displayLarge),
            ('displayMedium', theme.textTheme.displayMedium),
            ('displaySmall', theme.textTheme.displaySmall),
            ('headlineLarge', theme.textTheme.headlineLarge),
            ('headlineMedium', theme.textTheme.headlineMedium),
            ('headlineSmall', theme.textTheme.headlineSmall),
            ('titleLarge', theme.textTheme.titleLarge),
            ('titleMedium', theme.textTheme.titleMedium),
            ('titleSmall', theme.textTheme.titleSmall),
            ('bodyLarge', theme.textTheme.bodyLarge),
            ('bodyMedium', theme.textTheme.bodyMedium),
            ('bodySmall', theme.textTheme.bodySmall),
            ('labelLarge', theme.textTheme.labelLarge),
            ('labelMedium', theme.textTheme.labelMedium),
            ('labelSmall', theme.textTheme.labelSmall),
          ];
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final spec in styles)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(spec.$1,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: theme.colorScheme.primary)),
                        Text('The quick brown fox', style: spec.$2),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      Story(
        category: 'qtpi_ui / Structures',
        name: 'DsColumn',
        builder: (_) => const DsColumn(
          children: [Text('one'), Text('two'), Text('three')],
        ),
      ),
      Story(
        category: 'qtpi_ui / Structures',
        name: 'DsRow',
        builder: (_) => const DsRow(
          start: Text('left'),
          middle: Text('mid'),
          end: Text('right'),
        ),
      ),
      Story(
        category: 'qtpi_ui / Structures',
        name: 'DsGroup',
        builder: (_) => DsGroup(
          showChevron: true,
          onTap: () {},
          child: const Text('Tappable group row'),
        ),
      ),
    ];
