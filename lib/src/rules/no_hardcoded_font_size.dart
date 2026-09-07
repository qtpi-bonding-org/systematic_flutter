import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoHardcodedFontSize extends DartLintRule {
  const NoHardcodedFontSize() : super(code: _code);

  static const _code = LintCode(
    name: 'no_hardcoded_font_size',
    problemMessage: 'There is one text size, and AppSizes owns it.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addNamedExpression((node) {
      if (node.name.label.name == 'fontSize') {
        reporter.atNode(node, _code);
      }
    });
  }
}
