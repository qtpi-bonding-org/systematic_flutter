import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lint_config.dart';
import 'failure_helpers.dart';

/// Flags thrown Exceptions which are not one of the project's failure types.
/// Error values and broad Object/dynamic expressions are intentionally allowed.
class ThrowOnlyFailureTypes extends AnalysisRule {
  static const LintCode code = LintCode(
    'throw_only_failure_types',
    'Throw DomainException or EnvironmentException, not a general Exception.',
  );
  ThrowOnlyFailureTypes()
    : super(
        name: 'throw_only_failure_types',
        description: 'Restricts thrown exception values.',
      );
  @override
  LintCode get diagnosticCode => code;
  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (LintConfig.applies(context, name))
      registry.addThrowExpression(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);
  final AnalysisRule rule;
  @override
  void visitThrowExpression(ThrowExpression node) {
    final expression = node.expression;
    if (expression is SimpleIdentifier &&
        isCatchVariable(expression.name, expression))
      return;
    final type = expression.staticType;
    if (isException(type) && !isFailure(type) && !isError(type))
      rule.reportAtNode(node);
  }
}
