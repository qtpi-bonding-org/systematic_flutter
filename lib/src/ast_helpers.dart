import 'package:analyzer/dart/ast/ast.dart';

/// True if [expr] is `Type.member`, optionally scaled by a literal numeric
/// multiplier (`Type.member * 2` or `2 * Type.member`), for a `Type` whose
/// name is in [allowedTypes].
bool isTokenExpression(Expression expr, List<String> allowedTypes) {
  var target = expr;
  if (target is BinaryExpression && target.operator.lexeme == '*') {
    final left = target.leftOperand;
    final right = target.rightOperand;
    if (right is IntegerLiteral || right is DoubleLiteral) {
      target = left;
    } else if (left is IntegerLiteral || left is DoubleLiteral) {
      target = right;
    } else {
      return false;
    }
  }
  if (target is PrefixedIdentifier) {
    return allowedTypes.contains(target.prefix.name);
  }
  return false;
}

/// The lexeme of the nearest enclosing class declaration, or null if
/// [node] has none (e.g. a top-level function).
String? enclosingClassName(AstNode node) {
  return node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;
}
