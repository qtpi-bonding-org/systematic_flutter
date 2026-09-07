import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../../generated_config.dart';
import '../ast_helpers.dart';

class NoRawSizedboxSpacing extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_raw_sizedbox_spacing',
    'Use VSpace/HSpace for spacing, not a raw SizedBox.',
  );

  NoRawSizedboxSpacing()
    : super(
        name: 'no_raw_sizedbox_spacing',
        description:
            'Flags a spacing SizedBox outside the token spacer '
            'classes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, noRawSizedboxSpacingAllowedEnclosingClasses);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final List<String> allowedEnclosingClasses;

  _Visitor(this.rule, this.allowedEnclosingClasses);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme != 'SizedBox') return;
    final isSpacingArg = node.argumentList.arguments.any(
      (arg) =>
          arg is NamedArgument &&
          (arg.name.lexeme == 'height' || arg.name.lexeme == 'width'),
    );
    if (!isSpacingArg) return;
    final enclosing = enclosingClassName(node);
    if (enclosing != null && allowedEnclosingClasses.contains(enclosing)) {
      return;
    }
    rule.reportAtNode(node);
  }
}
