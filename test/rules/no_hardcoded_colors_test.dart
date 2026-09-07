import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_lint_generator/src/rules/no_hardcoded_colors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoHardcodedColorsTest);
  });
}

@reflectiveTest
class NoHardcodedColorsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoHardcodedColors();
    super.setUp();
  }

  Future<void> test_flags_color_and_banned_types() async {
    await assertDiagnostics(
      r'''
class Color {
  Color(int value);
}

class Colors {
  Colors._();
  static const red = 1;
}

class AppPalette {
  AppPalette._();
  static const red = 1;
}

final a = Color(0xFF00FF00);
final b = Colors.red;
final c = AppPalette.red;
''',
      [lint(167, 17), lint(196, 10), lint(218, 14)],
    );
  }
}
