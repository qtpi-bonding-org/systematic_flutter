import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_duplicate_cubitfield_keys.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDuplicateCubitFieldKeysTest);
  });
}

@reflectiveTest
class NoDuplicateCubitFieldKeysTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoDuplicateCubitFieldKeys();
    super.setUp();
  }

  Future<void> test_flags_duplicate_selector_key() async {
    await assertDiagnostics(
      r'''
T cubitField<T>(T Function() selector) => selector();

int selectorA() => 1;

final a = cubitField(selectorA);
final b = cubitField(selectorA);
''',
      [lint(121, 21)],
    );
  }
}
