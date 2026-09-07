import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../../generated_config.dart';
import '../ast_helpers.dart';

class NoHardcodedFontFamily extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_hardcoded_font_family',
    'There is one font family, and AppFonts owns it.',
  );

  NoHardcodedFontFamily()
    : super(
        name: 'no_hardcoded_font_family',
        description:
            'Flags a fontFamily argument not routed through an '
            'allowed token type.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, noHardcodedFontFamilyAllowedTypes);
    registry.addNamedArgument(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final List<String> allowedTypes;

  _Visitor(this.rule, this.allowedTypes);

  @override
  void visitNamedArgument(NamedArgument node) {
    if (node.name.lexeme != 'fontFamily') return;
    if (!isTokenExpression(node.argumentExpression2, allowedTypes)) {
      rule.reportAtNode(node.argumentExpression2);
    }
  }
}
