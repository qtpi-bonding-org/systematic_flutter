import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_lint_generator/src/rules/require_static_selector.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RequireStaticSelectorTest);
  });
}

@reflectiveTest
class RequireStaticSelectorTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = RequireStaticSelector();
    super.setUp();
  }

  Future<void> test_flags_inline_closure_selector() async {
    await assertDiagnostics(
      r'''
T cubitField<T>(T Function() selector) => selector();

int topLevelSelector() => 1;

final a = cubitField(topLevelSelector);
final b = cubitField(() => 1);
''',
      [lint(146, 7)],
    );
  }
}
