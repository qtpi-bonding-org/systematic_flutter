import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../../generated_config.dart';

class NoInlineWidgetCompositionInPages extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_inline_widget_composition_in_pages',
    'Pages must compose already-built reusable widgets, not construct '
        'layout widgets inline.',
  );

  NoInlineWidgetCompositionInPages()
    : super(
        name: 'no_inline_widget_composition_in_pages',
        description:
            'Flags banned widget construction inline in a '
            "page/screen class's build().",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final path =
        context.currentUnit?.file.path ?? context.definingUnit.file.path;
    final segments = path.split(RegExp(r'[\\/]'));
    if (segments.any(noInlineWidgetCompositionInPagesWidgetDirNames.contains)) {
      return;
    }

    final visitor = _Visitor(
      this,
      noInlineWidgetCompositionInPagesPageSuffix,
      noInlineWidgetCompositionInPagesBannedWidgetNames,
    );
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final String pageSuffix;
  final List<String> bannedWidgetNames;

  _Visitor(this.rule, this.pageSuffix, this.bannedWidgetNames);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!node.namePart.typeName.lexeme.endsWith(pageSuffix)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is MethodDeclaration && member.name.lexeme == 'build') {
        member.body.accept(_BannedWidgetVisitor(rule, bannedWidgetNames));
      }
    }
  }
}

class _BannedWidgetVisitor extends RecursiveAstVisitor<void> {
  final AnalysisRule rule;
  final List<String> bannedWidgetNames;

  _BannedWidgetVisitor(this.rule, this.bannedWidgetNames);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (bannedWidgetNames.contains(node.constructorName.type.name.lexeme)) {
      rule.reportAtNode(node);
    }
    super.visitInstanceCreationExpression(node);
  }
}
