import 'package:flutter/material.dart';
import '../primitives/app_spacings.dart';

class DsColumn extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAlignment;
  final MainAxisAlignment mainAlignment;
  final MainAxisSize mainAxisSize;
  final Widget? spacing;

  const DsColumn({
    super.key,
    required this.children,
    this.crossAlignment = CrossAxisAlignment.start,
    this.mainAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
  });

  Widget get _defaultSpacing => VSpace.x1;

  @override
  Widget build(BuildContext context) {
    if (children.length <= 1) {
      return Column(
        crossAxisAlignment: crossAlignment,
        mainAxisAlignment: mainAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    final spacedChildren = <Widget>[];
    final actualSpacing = spacing ?? _defaultSpacing;
    for (var i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i != children.length - 1) spacedChildren.add(actualSpacing);
    }

    return Column(
      crossAxisAlignment: crossAlignment,
      mainAxisAlignment: mainAlignment,
      mainAxisSize: mainAxisSize,
      children: spacedChildren,
    );
  }
}
