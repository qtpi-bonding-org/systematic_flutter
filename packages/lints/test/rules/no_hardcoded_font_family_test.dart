import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_hardcoded_font_family.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoHardcodedFontFamilyTest);
  });
}

@reflectiveTest
class NoHardcodedFontFamilyTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoHardcodedFontFamily();
    super.setUp();
  }

  Future<void> test_flags_raw_fontFamily() async {
    await assertDiagnostics(
      r'''
class TextStyle {
  const TextStyle({String? fontFamily});
}

class AppFonts {
  AppFonts._();
  static const mono = 'NotoSansMono';
}

const good = TextStyle(fontFamily: AppFonts.mono);
const bad = TextStyle(fontFamily: 'Comic Sans');
''',
      [lint(221, 12)],
    );
  }
}
