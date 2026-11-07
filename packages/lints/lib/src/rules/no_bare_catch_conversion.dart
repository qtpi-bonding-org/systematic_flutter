import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../lint_config.dart';
import 'failure_helpers.dart';

/// Flags a broad catch that creates a new systematic failure. Failure names
/// are matched by element name, intentionally without requiring a package URI.
class NoBareCatchConversion extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_bare_catch_conversion',
    'Do not convert a broad catch directly into a new failure.',
  );

  NoBareCatchConversion()
    : super(
        name: 'no_bare_catch_conversion',
        description: 'Flags failure conversion in broad catches.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (LintConfig.applies(context, name)) {
      registry.addCatchClause(this, _Visitor(this));
    }
  }
}

/// Compatibility for clients that used the original stub class.
class NoConvertingBareCatch extends NoBareCatchConversion {}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);
  final AnalysisRule rule;

  @override
  void visitCatchClause(CatchClause node) {
    final type = node.exceptionType?.toSource();
    if (type != null && type != 'Object' && type != 'Exception') return;

    var createsFailure = false;
    node.body.accept(
      _CreationVisitor((staticType) {
        if (isFailure(staticType)) createsFailure = true;
      }),
    );

    // With an implicit default constructor, analyzer 14 exposes `X()` as a
    // MethodInvocation rather than an InstanceCreationExpression. The source
    // fallback preserves the required NEW-expression distinction for the two
    // explicitly recognized failure base names.
    final source = node.body.toSource();
    if (RegExp(
      r'\b(DomainException|EnvironmentException)\s*\(',
    ).hasMatch(source)) {
      createsFailure = true;
    }
    if (createsFailure) rule.reportAtNode(node);
  }
}

class _CreationVisitor extends SimpleAstVisitor<void> {
  _CreationVisitor(this.onType);
  final void Function(DartType?) onType;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    onType(node.staticType);
  }
}
