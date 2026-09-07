import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoHardcodedColors extends DartLintRule {
  NoHardcodedColors({required this.bannedTypes}) : super(code: _code);

  final List<String> bannedTypes;

  static const _code = LintCode(
    name: 'no_hardcoded_colors',
    problemMessage:
        'Colour must come from a role (TextRole, SectionState, ActionKind) '
        'or context.colorScheme, never a literal Color or a palette '
        'constant.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.type.name2.lexeme == 'Color') {
        reporter.atNode(node, _code);
      }
    });
    context.registry.addPrefixedIdentifier((node) {
      if (bannedTypes.contains(node.prefix.name)) {
        reporter.atNode(node, _code);
      }
    });
  }
}
