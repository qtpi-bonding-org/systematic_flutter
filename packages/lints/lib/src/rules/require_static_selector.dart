import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../lint_config.dart';

class RequireStaticSelector extends AnalysisRule {
  static const LintCode code = LintCode(
    'require_static_selector',
    'cubitField selectors must be static or top-level tear-offs.',
  );

  RequireStaticSelector()
    : super(
        name: 'require_static_selector',
        description:
            'Flags a cubitField(...) selector that is an inline '
            'closure.',
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
    if (argument is FunctionExpression || argument is FunctionReference) {
      rule.reportAtNode(argument);
    }
  }
}
