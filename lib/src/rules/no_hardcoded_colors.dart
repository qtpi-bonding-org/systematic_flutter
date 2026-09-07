import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../../generated_config.dart';

class NoHardcodedColors extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_hardcoded_colors',
    'Colour must come from a role (TextRole, SectionState, ActionKind) or '
        'context.colorScheme, never a literal Color or a palette constant.',
  );

  NoHardcodedColors()
    : super(
        name: 'no_hardcoded_colors',
        description:
            'Flags Color(...) construction and banned static '
            'color-type access.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, noHardcodedColorsBannedTypes);
    registry
      ..addInstanceCreationExpression(this, visitor)
      ..addPrefixedIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final List<String> bannedTypes;

  _Visitor(this.rule, this.bannedTypes);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == 'Color') {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (bannedTypes.contains(node.prefix.name)) {
      rule.reportAtNode(node);
    }
  }
}
