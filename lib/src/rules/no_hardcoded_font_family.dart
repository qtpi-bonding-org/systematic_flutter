import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../ast_helpers.dart';

class NoHardcodedFontFamily extends DartLintRule {
  NoHardcodedFontFamily({required this.allowedTypes}) : super(code: _code);

  final List<String> allowedTypes;

  static const _code = LintCode(
    name: 'no_hardcoded_font_family',
    problemMessage: 'There is one font family, and AppFonts owns it.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addNamedExpression((node) {
      if (node.name.label.name != 'fontFamily') return;
      if (!isTokenExpression(node.expression, allowedTypes)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
