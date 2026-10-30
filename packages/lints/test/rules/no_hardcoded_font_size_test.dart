import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_lint_generator/src/rules/no_hardcoded_font_size.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoHardcodedFontSizeTest);
  });
}

@reflectiveTest
class NoHardcodedFontSizeTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoHardcodedFontSize();
    super.setUp();
  }

  Future<void> test_flags_fontSize_argument() async {
    await assertDiagnostics(
      r'''
class TextStyle {
  const TextStyle({double? fontSize});
}

const style = TextStyle(fontSize: 14);
''',
      [lint(84, 12)],
    );
  }

  Future<void> test_no_fontSize_argument() async {
    await assertNoDiagnostics(r'''
class TextStyle {
  const TextStyle({double? fontSize});
}

const style = TextStyle();
''');
  }
}
