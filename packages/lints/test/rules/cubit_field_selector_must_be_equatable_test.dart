import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/cubit_field_selector_must_be_equatable.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CubitFieldSelectorMustBeEquatableTest);
  });
}

@reflectiveTest
class CubitFieldSelectorMustBeEquatableTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = CubitFieldSelectorMustBeEquatable();
    super.setUp();
  }

  Future<void> test_flags_list_literal_selector() async {
    await assertDiagnostics(
      r'''
T cubitField<T>(T Function() selector) => selector();

final a = cubitField(() => 1);
final b = cubitField(() => [1, 2]);
''',
      [lint(113, 6)],
    );
  }
}
