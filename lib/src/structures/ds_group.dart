import 'package:flutter/material.dart';
import '../primitives/app_spacings.dart';
import '../primitives/app_sizes.dart';

class DsGroup extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool showChevron;
  final Color? chevronColor;
  final String? testId;

  const DsGroup({
    super.key,
    required this.child,
    this.testId,
    this.onTap,
    this.padding,
    this.showChevron = false,
    this.chevronColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? AppPadding.listItem;
    final effectiveChevronColor = chevronColor ?? Theme.of(context).colorScheme.primary;

    if (onTap != null) {
      return Semantics(
        button: true,
        identifier: testId,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: Padding(
            padding: effectivePadding,
            child: showChevron
                ? Row(children: [
                    Expanded(child: child),
                    HSpace.x1,
                    ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right,
                        size: AppSizes.size20,
                        color: effectiveChevronColor,
                      ),
                    ),
                  ])
                : child,
          ),
        ),
      );
    }

    return Padding(padding: effectivePadding, child: child);
  }
}
