import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/throw_only_failure_types.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() => defineReflectiveSuite(
  () => defineReflectiveTests(ThrowOnlyFailureTypesTest),
);

@reflectiveTest
class ThrowOnlyFailureTypesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ThrowOnlyFailureTypes();
    super.setUp();
  }

  Future<void> test_exception_flagged() async =>
      assertDiagnostics('void f(Exception e) { throw e; }', [lint(22, 7)]);
  Future<void> test_domain_allowed() async => assertNoDiagnostics(
    'class DomainException implements Exception {} void f() { throw DomainException(); }',
  );
  Future<void> test_environment_allowed() async => assertNoDiagnostics(
    'class EnvironmentException implements Exception {} void f() { throw EnvironmentException(); }',
  );
  Future<void> test_error_allowed() async =>
      assertNoDiagnostics('void f(Error e) { throw e; }');
  Future<void> test_object_allowed() async =>
      assertNoDiagnostics('void f(Object e) { throw e; }');
  Future<void> test_catchRethrowAllowed() async =>
      assertNoDiagnostics('void f() { try {} catch (e) { throw e; } }');
}
