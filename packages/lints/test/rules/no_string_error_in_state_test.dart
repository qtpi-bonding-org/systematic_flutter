import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_string_error_in_state.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() => defineReflectiveSuite(
  () => defineReflectiveTests(NoStringErrorInStateTest),
);

@reflectiveTest
class NoStringErrorInStateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoStringErrorInState();
    super.setUp();
  }

  Future<void> test_defaultString_flagged() async {
    const c =
        'void f(String s) { X().withError(error: s); }\nclass X { void withError({Object? error}) {} }';
    await assertDiagnostics(c, [lint(c.indexOf('s);'), 1)]);
  }

  Future<void> test_applyFlow_flagged() async {
    const c =
        'void f() { X().applyFlow(error: "bad"); }\nclass X { void applyFlow({Object? error}) {} }';
    await assertDiagnostics(c, [lint(c.indexOf('"bad"'), 5)]);
  }

  Future<void> test_object_allowed() async {
    await assertNoDiagnostics(
      'void f(Object e) { X().withError(error: e); }\nclass X { void withError({Object? error}) {} }',
    );
  }

  Future<void> test_exception_allowed() async {
    await assertNoDiagnostics(
      'void f(Exception e) { X().withError(error: e); }\nclass X { void withError({Object? error}) {} }',
    );
  }

  Future<void> test_otherMethod_allowed() async {
    await assertNoDiagnostics(
      'void f(String e) { X().other(error: e); }\nclass X { void other({Object? error}) {} }',
    );
  }

  Future<void> test_otherArgument_allowed() async {
    await assertNoDiagnostics(
      'void f(String e) { X().withError(message: e); }\nclass X { void withError({Object? message}) {} }',
    );
  }
}
