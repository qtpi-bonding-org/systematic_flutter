import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

class RequireCubitFieldOverRawBlocApis extends AnalysisRule {
  static const LintCode code = LintCode(
    'require_cubitfield_over_raw_bloc_apis',
    'Use CubitAdapter.cubitField instead of raw Bloc rebuild APIs.',
  );

  RequireCubitFieldOverRawBlocApis()
    : super(
        name: 'require_cubitfield_over_raw_bloc_apis',
        description:
            'Flags context.watch/select and bare '
            'BlocBuilder/BlocSelector/BlocConsumer construction.',
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
    if (path.endsWith('cubit_adapter.dart')) return;

    final visitor = _Visitor(this);
    registry
      ..addMethodInvocation(this, visitor)
      ..addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _bannedConstructorNames = {
    'BlocBuilder',
    'BlocSelector',
    'BlocConsumer',
  };

  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name != 'watch' && name != 'select') return;
    final target = node.target;
    if (target is SimpleIdentifier && target.name == 'context') {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_bannedConstructorNames.contains(
      node.constructorName.type.name.lexeme,
    )) {
      rule.reportAtNode(node);
    }
  }
}
