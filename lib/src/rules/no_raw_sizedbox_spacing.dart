import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../ast_helpers.dart';

class NoRawSizedBoxSpacing extends DartLintRule {
  NoRawSizedBoxSpacing({required this.allowedEnclosingClasses})
      : super(code: _code);

  final List<String> allowedEnclosingClasses;

  static const _code = LintCode(
    name: 'no_raw_sizedbox_spacing',
    problemMessage: 'Use VSpace/HSpace for spacing, not a raw SizedBox.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.type.name2.lexeme != 'SizedBox') return;
      final isSpacingArg = node.argumentList.arguments.any((arg) =>
          arg is NamedExpression &&
          (arg.name.label.name == 'height' ||
              arg.name.label.name == 'width'));
      if (!isSpacingArg) return;
      final enclosing = enclosingClassName(node);
      if (enclosing != null && allowedEnclosingClasses.contains(enclosing)) {
        return;
      }
      reporter.atNode(node, _code);
    });
  }
}
