import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class NoHardcodedFontSize extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_hardcoded_font_size',
    'There is one text size, and AppSizes owns it.',
  );

  NoHardcodedFontSize()
    : super(
        name: 'no_hardcoded_font_size',
        description: 'Flags any hardcoded fontSize argument.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addNamedArgument(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitNamedArgument(NamedArgument node) {
    if (node.name.lexeme == 'fontSize') {
      rule.reportAtNode(node);
    }
  }
}
