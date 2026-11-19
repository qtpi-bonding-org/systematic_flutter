import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

@immutable
class TagChipData {
  const TagChipData({required this.label});

  final String label;

  static Map<String, TagChipData> samples() => const {
        'tag1': TagChipData(label: 'tag1'),
        'tag2': TagChipData(label: 'tag2'),
        'long': TagChipData(label: 'a rather long tag label'),
      };

  @override
  bool operator ==(Object other) =>
      other is TagChipData && other.label == label;

  @override
  int get hashCode => label.hashCode;
}

/// A tag label. Drawn with a DecoratedBox rather than a Chip: a Chip builds an
/// InkWell of its own, and the tap target here should be the only one.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.data, required this.onTap});

  final TagChipData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(context.sizes.radiusMedium);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: radius,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.sizes.space,
            vertical: context.sizes.spaceHalf,
          ),
          child: Text(
            data.label,
            style: TextStyle(color: scheme.onSecondaryContainer),
          ),
        ),
      ),
    );
  }
}
