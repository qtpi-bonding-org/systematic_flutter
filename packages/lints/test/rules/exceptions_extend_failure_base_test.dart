import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/exceptions_extend_failure_base.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExceptionsExtendFailureBaseTest);
  });
}

@reflectiveTest
class ExceptionsExtendFailureBaseTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ExceptionsExtendFailureBase();
    super.setUp();
  }

  Future<void> test_plainException_flagged() async =>
      assertDiagnostics('class X implements Exception {}', [lint(0, 31)]);
  Future<void> test_domainException_allowed() async =>
      assertNoDiagnostics('class DomainException implements Exception {}');
  Future<void> test_environmentSubtype_allowed() async =>
      assertNoDiagnostics('class EnvironmentException implements Exception {}');
  Future<void> test_nonException_allowed() async =>
      assertNoDiagnostics('class X {}');
  Future<void> test_error_allowed() async =>
      assertNoDiagnostics('class X extends Error {}');
  Future<void> test_indirectException_flagged() async => assertDiagnostics(
    'class Base implements Exception {} class X extends Base {}',
    [lint(0, 34), lint(35, 23)],
  );
}
