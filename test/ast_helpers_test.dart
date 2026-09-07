import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_ui_lints/src/ast_helpers.dart';
import 'package:test/test.dart';

Expression _parseExpr(String source) {
  final unit = parseString(content: 'final x = $source;').unit;
  final decl = unit.declarations.single as TopLevelVariableDeclaration;
  return decl.variables.variables.single.initializer!;
}

void main() {
  group('isTokenExpression', () {
    test('accepts a bare token member access', () {
      expect(isTokenExpression(_parseExpr('AppFonts.mono'), ['AppFonts']),
          isTrue);
    });

    test('accepts a token member scaled by a literal multiplier', () {
      expect(
          isTokenExpression(_parseExpr('AppSizes.space * 2'), ['AppSizes']),
          isTrue);
      expect(
          isTokenExpression(_parseExpr('2 * AppSizes.space'), ['AppSizes']),
          isTrue);
    });

    test('rejects a member access on a type not in allowedTypes', () {
      expect(isTokenExpression(_parseExpr('Other.mono'), ['AppFonts']),
          isFalse);
    });

    test('rejects a bare numeric literal', () {
      expect(isTokenExpression(_parseExpr('16'), ['AppFonts']), isFalse);
    });

    test('rejects two literals multiplied together', () {
      expect(isTokenExpression(_parseExpr('2 * 3'), ['AppFonts']), isFalse);
    });
  });

  group('enclosingClassName', () {
    test('finds the nearest enclosing class', () {
      final unit = parseString(content: '''
        class VSpace {
          static int get x1 => 1;
        }
      ''').unit;
      final classDecl = unit.declarations.single as ClassDeclaration;
      final getter = classDecl.members.single;
      expect(enclosingClassName(getter), 'VSpace');
    });

    test('returns null outside any class', () {
      final unit = parseString(content: 'final x = 1;').unit;
      expect(enclosingClassName(unit.declarations.single), isNull);
    });
  });
}
