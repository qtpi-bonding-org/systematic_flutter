import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoInlineWidgetCompositionInPages extends DartLintRule {
  NoInlineWidgetCompositionInPages({
    required this.pageSuffix,
    required this.widgetDirNames,
    required this.bannedWidgetNames,
  }) : super(code: _code);

  final String pageSuffix;
  final List<String> widgetDirNames;
  final List<String> bannedWidgetNames;

  static const _code = LintCode(
    name: 'no_inline_widget_composition_in_pages',
    problemMessage:
        'Pages must compose already-built reusable widgets, not construct '
        'layout widgets inline.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final segments = resolver.path.split(RegExp(r'[\\/]'));
    if (segments.any(widgetDirNames.contains)) return;

    context.registry.addClassDeclaration((classNode) {
      if (!classNode.name.lexeme.endsWith(pageSuffix)) return;

      for (final member in classNode.members) {
        if (member is MethodDeclaration && member.name.lexeme == 'build') {
          member.body.accept(
            _BannedWidgetVisitor(reporter, _code, bannedWidgetNames),
          );
        }
      }
    });
  }
}

class _BannedWidgetVisitor extends RecursiveAstVisitor<void> {
  _BannedWidgetVisitor(this.reporter, this.code, this.bannedWidgetNames);

  final ErrorReporter reporter;
  final LintCode code;
  final List<String> bannedWidgetNames;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (bannedWidgetNames.contains(node.constructorName.type.name2.lexeme)) {
      reporter.atNode(node, code);
    }
    super.visitInstanceCreationExpression(node);
  }
}
