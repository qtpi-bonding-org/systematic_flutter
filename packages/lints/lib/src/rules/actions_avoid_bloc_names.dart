import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../lint_config.dart';

/// Abstract or interface `*Actions` classes must not declare bloc-style
/// members, which would make them look like a cubit or bloc.
class ActionsAvoidBlocNames extends AnalysisRule {
  static const LintCode code = LintCode(
    'actions_avoid_bloc_names',
    'Actions classes must not declare bloc-style members.',
  );

  ActionsAvoidBlocNames()
    : super(
        name: 'actions_avoid_bloc_names',
        description:
            'Flags close/emit/onChange/onError/addError/state/stream/isClosed '
            'members on abstract or interface *Actions classes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!LintConfig.applies(context, name)) return;
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);
  final AnalysisRule rule;

  static const _bannedMembers = {
    'close',
    'emit',
    'onChange',
    'onError',
    'addError',
    'state',
    'stream',
    'isClosed',
  };

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!node.namePart.typeName.lexeme.endsWith('Actions')) return;
    if (node.abstractKeyword == null && node.interfaceKeyword == null) return;
    final body = node.body;
    if (body is! BlockClassBody) return;
    for (final member in body.members) {
      if (member is MethodDeclaration) {
        _check(member.name);
      } else if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          _check(variable.name);
        }
      }
    }
  }

  void _check(Token name) {
    if (_bannedMembers.contains(name.lexeme)) rule.reportAtToken(name);
  }
}
