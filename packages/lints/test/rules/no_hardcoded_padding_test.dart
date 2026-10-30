import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_lint_generator/src/rules/no_hardcoded_padding.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoHardcodedPaddingTest);
  });
}

@reflectiveTest
class NoHardcodedPaddingTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoHardcodedPadding();
    super.setUp();
  }

  Future<void> test_flags_raw_numeric_insets_not_scaled_tokens() async {
    await assertDiagnostics(
      r'''
class EdgeInsets {
  EdgeInsets.all(double value);
  EdgeInsets.only({double left = 0, double bottom = 0});
}

class AppSizes {
  AppSizes._();
  static const double space = 8;
}

final good = EdgeInsets.all(AppSizes.space);
final goodScaled = EdgeInsets.only(left: AppSizes.space * 2);
final bad = EdgeInsets.all(16);
final badOnly = EdgeInsets.only(left: 4, bottom: 8);
''',
      [lint(314, 2), lint(357, 1), lint(368, 1)],
    );
  }
}
