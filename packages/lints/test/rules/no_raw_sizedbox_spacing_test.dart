import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_raw_sizedbox_spacing.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoRawSizedboxSpacingTest);
  });
}

@reflectiveTest
class NoRawSizedboxSpacingTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoRawSizedboxSpacing();
    super.setUp();
  }

  Future<void> test_flags_raw_spacer() async {
    await assertDiagnostics(
      r'''
class SizedBox {
  SizedBox({double? width, double? height});
}

final x = SizedBox(height: 16);
''',
      [lint(75, 20)],
    );
  }
}
