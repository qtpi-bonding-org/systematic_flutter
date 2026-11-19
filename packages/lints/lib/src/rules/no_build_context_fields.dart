import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lint_config.dart';
import 'boundary_helpers.dart';

/// A BuildContext held in a field outlives the build that produced it. Only
/// a `State` may keep one, since its context is tied to the element's life.
class NoBuildContextFields extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_build_context_fields',
    'Do not hold a BuildContext in a field; pass it where it is used.',
  );

  NoBuildContextFields()
    : super(
        name: 'no_build_context_fields',
        description:
            'Flags BuildContext fields on any class or mixin except State '
            'subclasses.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!LintConfig.applies(context, name)) return;
    registry.addFieldDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);
  final AnalysisRule rule;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final typeAnnotation = node.fields.type;
    if (typeAnnotation is! NamedType) return;
    if (!isBuildContextType(typeAnnotation.type)) return;
    if (_isInState(node)) return;
    rule.reportAtNode(typeAnnotation);
  }

  /// True when the field's owner is a `State` subclass, or a mixin whose
  /// `on` constraints include one.
  bool _isInState(FieldDeclaration node) {
    final owner = node.parent?.parent;
    if (owner is ClassDeclaration) {
      final type = owner.declaredFragment?.element.thisType;
      return type != null && stateSupertype(type) != null;
    }
    if (owner is MixinDeclaration) {
      final element = owner.declaredFragment?.element;
      if (element == null) return false;
      if (stateSupertype(element.thisType) != null) return true;
      return element.superclassConstraints.any(
        (constraint) => stateSupertype(constraint) != null,
      );
    }
    return false;
  }
}
