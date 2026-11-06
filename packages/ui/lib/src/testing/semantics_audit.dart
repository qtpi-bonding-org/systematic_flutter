/// Semantics audit for widget tests: finds operable controls a screen reader
/// cannot name.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// One actionable semantics node that a screen reader (or the Flutter driver's
/// semantics finder) cannot name.
class UnlabeledControl {
  const UnlabeledControl({
    required this.rect,
    required this.actions,
    required this.creator,
  });

  /// Global rectangle of the node.
  final Rect rect;

  /// Names of the actions the node offers (tap, setText, ...).
  final List<String> actions;

  /// Creator chain of the widget under the node's centre, innermost first.
  final String creator;

  @override
  String toString() => '$actions at $rect  <-  $creator';
}

const _interactive = <SemanticsAction>[
  SemanticsAction.tap,
  SemanticsAction.longPress,
  SemanticsAction.setText,
  SemanticsAction.increase,
  SemanticsAction.decrease,
];

/// Walks the live semantics tree and returns every visible node that can be
/// operated but has no label, value, hint or tooltip.
///
/// The caller must hold a `tester.ensureSemantics()` handle for the duration.
List<UnlabeledControl> auditUnlabeledControls(WidgetTester tester) {
  final owner = tester.binding.renderViews.first.owner?.semanticsOwner;
  final root = owner?.rootSemanticsNode;
  if (root == null) {
    throw StateError(
      'Semantics are not enabled; call tester.ensureSemantics().',
    );
  }
  final found = <UnlabeledControl>[];

  void visit(SemanticsNode node, Matrix4 parentTransform) {
    final data = node.getSemanticsData();
    if (!data.flagsCollection.isHidden) {
      final actions = [
        for (final a in _interactive)
          if (data.hasAction(a)) a,
      ];
      final named = data.label.trim().isNotEmpty ||
          data.value.trim().isNotEmpty ||
          data.hint.trim().isNotEmpty ||
          data.tooltip.trim().isNotEmpty;
      if (actions.isNotEmpty && !named) {
        final dpr =
            tester.binding.renderViews.first.flutterView.devicePixelRatio;
        // The semantics root carries the device-pixel-ratio scale; hit testing
        // and the reported rect are in logical pixels.
        final physical = MatrixUtils.transformRect(
          _globalTransform(node),
          node.rect,
        );
        final global = Rect.fromLTRB(
          physical.left / dpr,
          physical.top / dpr,
          physical.right / dpr,
          physical.bottom / dpr,
        );
        found.add(
          UnlabeledControl(
            rect: global,
            actions: [for (final a in actions) a.toString().split('.').last],
            creator: _creatorOf(tester, node),
          ),
        );
      }
    }
    node.visitChildren((child) {
      visit(child, parentTransform);
      return true;
    });
  }

  visit(root, Matrix4.identity());
  return found;
}

Matrix4 _globalTransform(SemanticsNode node) {
  final chain = <SemanticsNode>[];
  for (SemanticsNode? n = node; n != null; n = n.parent) {
    chain.add(n);
  }
  final m = Matrix4.identity();
  for (final n in chain.reversed) {
    final t = n.transform;
    if (t != null) m.multiply(t);
  }
  return m;
}

String _creatorOf(WidgetTester tester, SemanticsNode node) {
  String? chain;
  void walk(RenderObject object) {
    if (chain != null) return;
    if (object.debugSemantics?.id == node.id) {
      final creator = object.debugCreator;
      if (creator is DebugCreator) {
        chain = creator.element.debugGetCreatorChain(10);
        return;
      }
    }
    object.visitChildren(walk);
  }

  walk(tester.binding.renderViews.first);
  return chain ?? 'unknown';
}
