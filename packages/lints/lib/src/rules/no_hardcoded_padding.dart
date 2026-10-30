import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../lint_config.dart';

class NoHardcodedPadding extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_hardcoded_padding',
    'Padding insets must come from AppSizes, never a raw number.',
  );

  NoHardcodedPadding()
    : super(
        name: 'no_hardcoded_padding',
        description: 'Flags raw numeric EdgeInsets arguments.',
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
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _constructorNames = {'all', 'only', 'symmetric'};

  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    if (constructorName.type.name.lexeme != 'EdgeInsets') return;
    if (!_constructorNames.contains(constructorName.name?.name)) return;

    for (final arg in node.argumentList.arguments) {
      final expr = arg is NamedArgument ? arg.argumentExpression2 : arg;
      if (expr is IntegerLiteral || expr is DoubleLiteral) {
        rule.reportAtNode(expr);
      } else if (expr is PrefixExpression &&
          (expr.operand is IntegerLiteral || expr.operand is DoubleLiteral)) {
        rule.reportAtNode(expr);
      }
    }
  }
}
