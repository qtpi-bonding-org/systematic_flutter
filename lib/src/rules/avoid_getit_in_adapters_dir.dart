import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class AvoidGetItInAdaptersDir extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_getit_in_adapters_dir',
    'Adapters must not construct or locate dependencies.',
  );

  AvoidGetItInAdaptersDir()
    : super(
        name: 'avoid_getit_in_adapters_dir',
        description:
            'Flags GetIt/injectable imports in an adapters/ '
            'file.',
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
    if (!path.split(RegExp(r'[\\/]')).contains('adapters')) return;

    final visitor = _Visitor(this);
    registry.addImportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _bannedUris = {
    'package:get_it/get_it.dart',
    'package:injectable/injectable.dart',
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
