import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class AvoidBlocImportsInWidgetsDir extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_bloc_imports_in_widgets_dir',
    'Widgets must not import Cubit, DI, or routing APIs.',
  );

  AvoidBlocImportsInWidgetsDir()
    : super(
        name: 'avoid_bloc_imports_in_widgets_dir',
        description: 'Flags Cubit/DI/routing imports in a widgets/ file.',
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
    if (!path.split(RegExp(r'[\\/]')).contains('widgets')) return;

    final visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _bannedUris = {
    'package:flutter_bloc/flutter_bloc.dart',
    'package:get_it/get_it.dart',
    'package:injectable/injectable.dart',
    'package:go_router/go_router.dart',
  };

  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitImportDirective(ImportDirective node) {
    if (_bannedUris.contains(node.uri.stringValue)) {
      rule.reportAtNode(node);
    }
  }
}
