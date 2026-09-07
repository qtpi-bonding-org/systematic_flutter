import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoHardcodedStrings extends DartLintRule {
  NoHardcodedStrings({required this.allowedTypes}) : super(code: _code);

  final List<String> allowedTypes;

  static const _code = LintCode(
    name: 'no_hardcoded_strings',
    problemMessage:
        'User-facing text must come from MessageKey, never a hardcoded '
        'string.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final constructorName = node.constructorName;
      if (constructorName.type.name2.lexeme != 'Text') return;
      if (constructorName.name != null) return; // skip Text.rich, etc.
      final args = node.argumentList.arguments;
      if (args.isEmpty) return;
      final first = args.first;
      final expr = first is NamedExpression ? first.expression : first;
      if (expr is StringLiteral) {
        reporter.atNode(expr, _code);
      }
    });
  }
}
