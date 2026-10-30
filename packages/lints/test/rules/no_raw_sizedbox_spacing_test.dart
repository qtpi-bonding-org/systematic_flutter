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
  SizedBox({double? width, double? height, Object? child});
}

final x = SizedBox(height: 16);
''',
      [lint(90, 20)],
    );
  }

  Future<void> test_flags_horizontal_spacer() async {
    await assertDiagnostics(
      r'''
class SizedBox {
  SizedBox({double? width, double? height, Object? child});
}

final x = SizedBox(width: 8);
''',
      [lint(90, 18)],
    );
  }

  Future<void> test_ignores_box_with_child() async {
    await assertNoDiagnostics(r'''
class SizedBox {
  SizedBox({double? width, double? height, Object? child});
}

final x = SizedBox(height: 16, child: Object());
''');
  }

  Future<void> test_ignores_fixed_size_box() async {
    await assertNoDiagnostics(r'''
class SizedBox {
  SizedBox({double? width, double? height, Object? child});
}

final x = SizedBox(width: 16, height: 16);
''');
  }
}
