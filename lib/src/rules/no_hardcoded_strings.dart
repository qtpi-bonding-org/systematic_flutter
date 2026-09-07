import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class NoHardcodedStrings extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_hardcoded_strings',
    'User-facing text must come from MessageKey, never a hardcoded string.',
  );

  NoHardcodedStrings()
    : super(
        name: 'no_hardcoded_strings',
        description:
            'Flags a string literal passed as the first argument to '
            'Text(...).',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    if (constructorName.type.name.lexeme != 'Text') return;
    if (constructorName.name != null) return; // skip Text.rich, etc.

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;
    final first = args.first;
    final expr = first is NamedArgument ? first.argumentExpression2 : first;
    if (expr is StringLiteral) {
      rule.reportAtNode(expr);
    }
  }
}
