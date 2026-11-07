import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lint_config.dart';
import 'failure_helpers.dart';

/// Requires classes that implement/extend dart:core Exception to also extend
/// a DomainException or EnvironmentException. Failure names are matched by
/// element name deliberately; they need not come from a particular library.
class ExceptionsExtendFailureBase extends AnalysisRule {
  static const LintCode code = LintCode(
    'exceptions_extend_failure_base',
    'Exception classes must extend DomainException or EnvironmentException.',
  );

  ExceptionsExtendFailureBase()
    : super(
        name: 'exceptions_extend_failure_base',
        description: 'Requires systematic failure bases for exceptions.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!LintConfig.applies(context, name)) return;
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);
  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final type = node.declaredFragment?.element.thisType;
    if (isException(type) && !isFailure(type)) rule.reportAtNode(node);
  }
}
