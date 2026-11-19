import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lint_config.dart';
import 'boundary_helpers.dart';

/// Widgets that extend an adapter base end in `Adapter`; no other widget does.
class AdapterNaming extends AnalysisRule {
  static const LintCode code = LintCode(
    'adapter_naming',
    'Adapter widgets must end in Adapter, and other widgets must not.',
  );

  AdapterNaming()
    : super(
        name: 'adapter_naming',
        description:
            'Requires the Adapter suffix on adapter widgets and forbids it '
            'on other widgets.',
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
    if (type == null || !isWidgetType(type)) return;
    final name = node.namePart.typeName;
    if (adapterBaseNames.contains(name.lexeme)) return;
    final isAdapter = type.allSupertypes.any(
      (supertype) => adapterBaseNames.contains(supertype.element.name),
    );
    final hasSuffix = name.lexeme.endsWith('Adapter');
    if (isAdapter != hasSuffix) rule.reportAtToken(name);
  }
}
