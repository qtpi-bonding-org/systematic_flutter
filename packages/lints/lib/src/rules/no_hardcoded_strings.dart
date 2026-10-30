import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../lint_config.dart';

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
    if (!LintConfig.applies(context, name)) return;
    final config = LintConfig.forContext(context);
    final visitor = _Visitor(
      this,
      config.list(name, 'text_arguments', _defaultTextArguments).toSet(),
    );
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

/// Named arguments whose value is text the user reads or hears.
const _defaultTextArguments = [
  'tooltip',
  'semanticLabel',
  'hintText',
  'labelText',
  'helperText',
  'errorText',
  'label',
  'hint',
];

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final Set<String> textArguments;

  _Visitor(this.rule, this.textArguments);

  @override
  void visitMethodInvocation(MethodInvocation node) =>
      _checkNamed(node.argumentList);

  /// A literal with no letter ('', '•', ' ') carries no wording to translate.
  static bool _hasWording(StringLiteral literal) => switch (literal) {
    SimpleStringLiteral(:final value) => RegExp(
      r'\p{L}',
      unicode: true,
    ).hasMatch(value),
    StringInterpolation(:final elements) =>
      elements.whereType<InterpolationString>().any(
        (e) => RegExp(r'\p{L}', unicode: true).hasMatch(e.value),
      ),
    _ => true,
  };

  void _checkNamed(ArgumentList list) {
    for (final arg in list.arguments) {
      if (arg is! NamedArgument) continue;
      if (!textArguments.contains(arg.name.lexeme)) continue;
      final expr = arg.argumentExpression2;
      if (expr is StringLiteral && _hasWording(expr)) rule.reportAtNode(expr);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _checkNamed(node.argumentList);
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
