import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import '../lint_config.dart';
import 'failure_helpers.dart';

class NoErrorToText extends AnalysisRule {
  static const code = LintCode(
    'no_error_to_text',
    'Do not convert an Exception or Error to text here.',
  );
  NoErrorToText()
    : super(
        name: 'no_error_to_text',
        description: 'Flags text conversion of statically known errors.',
      );
  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry r, RuleContext c) {
    if (!LintConfig.applies(c, name)) return;
    final config = LintConfig.forContext(c);
    final allowed = config.list(name, 'allowed_files', const []);
    final root = c.package?.root.path;
    final unit = c.currentUnit ?? c.definingUnit;
    if (root != null) {
      final relative = p
          .relative(unit.file.path, from: root)
          .replaceAll(r'\', '/');
      if (allowed.any((pattern) => Glob(pattern).matches(relative))) return;
    }
    final visitor = _Visitor(this, config.list(name, 'logger_types', const []));
    r
      ..addMethodInvocation(this, visitor)
      ..addInterpolationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final List<String> loggerTypes;
  _Visitor(this.rule, this.loggerTypes);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'toString' &&
        node.argumentList.arguments.isEmpty &&
        node.target != null &&
        _bad(node.target!.staticType) &&
        !_loggerArgument(node)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (_bad(node.expression.staticType) && !_loggerArgument(node))
      rule.reportAtNode(node);
  }

  bool _loggerArgument(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is ArgumentList) {
        final call = current.parent;
        if (call is MethodInvocation &&
            call.target?.staticType is InterfaceType) {
          return loggerTypes.contains(
            (call.target!.staticType as InterfaceType).element.name,
          );
        }
      }
      current = current.parent;
    }
    return false;
  }
}

bool _bad(DartType? type) => isException(type) || isError(type);
