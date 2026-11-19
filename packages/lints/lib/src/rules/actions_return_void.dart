import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../lint_config.dart';

/// `*Actions` types are command surfaces: each member runs an effect and
/// reports nothing back through its type, so members return `void` or
/// `Future<void>`.
class ActionsReturnVoid extends AnalysisRule {
  static const LintCode code = LintCode(
    'actions_return_void',
    'Members of *Actions must return void or Future<void>.',
  );

  ActionsReturnVoid()
    : super(
        name: 'actions_return_void',
        description:
            'Requires instance members of abstract, interface and mixin '
            '*Actions types to return void or Future<void>.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!LintConfig.applies(context, name)) return;
    registry
      ..addClassDeclaration(this, _Visitor(this))
      ..addMixinDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);
  final AnalysisRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!node.namePart.typeName.lexeme.endsWith('Actions')) return;
    final isMixinClass = node.mixinKeyword != null;
    if (node.abstractKeyword == null &&
        node.interfaceKeyword == null &&
        !isMixinClass) {
      return;
    }
    final body = node.body;
    if (body is BlockClassBody) _checkMembers(body.members);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    if (!node.name.lexeme.endsWith('Actions')) return;
    _checkMembers(node.body.members);
  }

  void _checkMembers(Iterable<ClassMember> members) {
    for (final member in members) {
      if (member is MethodDeclaration) {
        if (member.isStatic || member.isSetter) continue;
        if (!_isVoidOrFutureVoid(_returnType(member))) {
          rule.reportAtToken(member.name);
        }
      } else if (member is FieldDeclaration) {
        if (member.isStatic) continue;
        for (final variable in member.fields.variables) {
          rule.reportAtToken(variable.name);
        }
      }
    }
  }

  DartType? _returnType(MethodDeclaration member) =>
      member.declaredFragment?.element.returnType;

  bool _isVoidOrFutureVoid(DartType? type) {
    if (type is VoidType) return true;
    if (type is! InterfaceType) return false;
    if (type.nullabilitySuffix != NullabilitySuffix.none) return false;
    final element = type.element;
    if (element.name != 'Future' ||
        element.library.uri.toString() != 'dart:async') {
      return false;
    }
    final args = type.typeArguments;
    return args.length == 1 && args.single is VoidType;
  }
}
