import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../lint_config.dart';

class CubitFieldSelectorMustBeEquatable extends AnalysisRule {
  static const LintCode code = LintCode(
    'cubit_field_selector_must_be_equatable',
    'Selector outputs should have stable value equality.',
  );

  CubitFieldSelectorMustBeEquatable()
    : super(
        name: 'cubit_field_selector_must_be_equatable',
        description:
            'Flags a cubitField(...) selector returning a '
            'List/Set/Map/Record literal.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!LintConfig.applies(context, name)) return;
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'cubitField') return;
    final arguments = node.argumentList.arguments;
    if (arguments.isEmpty) return;
    final argument = arguments.first;
    if (argument is! FunctionExpression) return;
    final body = argument.body;
    if (body is! ExpressionFunctionBody) return;
    final expression = body.expression;
    if (expression is ListLiteral ||
        expression is SetOrMapLiteral ||
        expression is RecordLiteral) {
      rule.reportAtNode(expression);
    }
  }
}
