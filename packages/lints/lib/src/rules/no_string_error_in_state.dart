import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../lint_config.dart';

class NoStringErrorInState extends AnalysisRule {
  static const code = LintCode(
    'no_string_error_in_state',
    'State error values must not be strings.',
  );
  NoStringErrorInState()
    : super(
        name: 'no_string_error_in_state',
        description: 'Flags String values passed as error state arguments.',
      );
  LintCode get diagnosticCode => code;
  void registerNodeProcessors(RuleVisitorRegistry r, RuleContext c) {
    if (!LintConfig.applies(c, name)) return;
    final cfg = LintConfig.forContext(c);
    r.addMethodInvocation(
      this,
      _Visitor(
        this,
        cfg.list(name, 'mutators', const ['withError', 'applyFlow']),
        cfg.list(name, 'argument_names', const ['error']),
      ),
    );
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final List<String> mutators, names;
  _Visitor(this.rule, this.mutators, this.names);
  void visitMethodInvocation(MethodInvocation n) {
    if (!mutators.contains(n.methodName.name)) return;
    for (final arg in n.argumentList.arguments) {
      if (arg is NamedArgument &&
          names.contains(arg.name.lexeme) &&
          arg.argumentExpression2.staticType?.getDisplayString() == 'String') {
        rule.reportAtNode(arg.argumentExpression2);
      }
    }
  }
}
