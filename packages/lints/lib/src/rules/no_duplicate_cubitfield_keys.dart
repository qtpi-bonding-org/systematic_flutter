import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../lint_config.dart';

class NoDuplicateCubitFieldKeys extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_duplicate_cubitfield_keys',
    'Avoid declaring duplicate cubitField selectors in one adapter.',
  );

  NoDuplicateCubitFieldKeys()
    : super(
        name: 'no_duplicate_cubitfield_keys',
        description:
            'Flags a repeated cubitField(sameSelector) call in '
            'one file.',
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
  final Map<String, MethodInvocation> _seen = {};

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'cubitField') return;
    final arguments = node.argumentList.arguments;
    if (arguments.isEmpty) return;
    final argument = arguments.first;
    if (argument is! SimpleIdentifier) return;
    final previous = _seen[argument.name];
    if (previous != null) rule.reportAtNode(node);
    _seen[argument.name] = node;
  }
}
