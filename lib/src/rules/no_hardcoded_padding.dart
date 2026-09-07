import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoHardcodedPadding extends DartLintRule {
  const NoHardcodedPadding() : super(code: _code);

  static const _code = LintCode(
    name: 'no_hardcoded_padding',
    problemMessage:
        'Padding insets must come from AppSizes, never a raw number.',
  );

  static const _constructorNames = {'all', 'only', 'symmetric'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final constructorName = node.constructorName;
      if (constructorName.type.name2.lexeme != 'EdgeInsets') return;
      if (!_constructorNames.contains(constructorName.name?.name)) return;

      for (final arg in node.argumentList.arguments) {
        final expr = arg is NamedExpression ? arg.expression : arg;
        if (expr is IntegerLiteral || expr is DoubleLiteral) {
          reporter.atNode(expr, _code);
        } else if (expr is PrefixExpression &&
            (expr.operand is IntegerLiteral ||
                expr.operand is DoubleLiteral)) {
          reporter.atNode(expr, _code);
        }
      }
    });
  }
}
