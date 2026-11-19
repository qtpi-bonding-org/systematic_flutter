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
///
/// `ClassDeclaration.name` was removed in favor of `.namePart.typeName`
/// when primary-constructor support landed (analyzer 13+).
String? enclosingClassName(AstNode node) {
  return node
      .thisOrAncestorOfType<ClassDeclaration>()
      ?.namePart
      .typeName
      .lexeme;
}

/// True for `Connect(...)` / `Connect2(...)`, the bloc-select widgets whose
/// `select:` argument follows the cubitField selector rules.
bool isConnectCreation(InstanceCreationExpression node) {
  final name = node.constructorName.type.name.lexeme;
  return name == 'Connect' || name == 'Connect2';
}

/// The value of the named argument [name] in [list], or null when absent.
Expression? namedArgumentValue(ArgumentList list, String name) {
  for (final argument in list.arguments) {
    if (argument is NamedArgument && argument.name.lexeme == name) {
      // ignore: experimental_member_use
      return argument.argumentExpression2;
    }
  }
  return null;
}
