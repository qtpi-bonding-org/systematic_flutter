import 'package:flutter/material.dart';
import '../primitives/app_spacings.dart';

class DsRow extends StatelessWidget {
  final Widget? start;
  final Widget? middle;
  final Widget? end;
  final CrossAxisAlignment alignment;
  final Widget? spacing;

  const DsRow({
    super.key,
    this.start,
    this.middle,
    this.end,
    this.alignment = CrossAxisAlignment.start,
    this.spacing,
  });

  Widget get _defaultSpacing => HSpace.x2;

  @override
  Widget build(BuildContext context) {
    final actualSpacing = spacing ?? _defaultSpacing;
    return Row(
      crossAxisAlignment: alignment,
      children: [
        if (start != null) ...[start!, actualSpacing],
        if (middle != null) Expanded(child: middle!) else const Spacer(),
        if (end != null) ...[actualSpacing, end!],
      ],
    );
  }
}
