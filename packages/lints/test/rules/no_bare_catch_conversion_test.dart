import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_bare_catch_conversion.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() => defineReflectiveSuite(
  () => defineReflectiveTests(NoBareCatchConversionTest),
);

@reflectiveTest
class NoBareCatchConversionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoBareCatchConversion();
    super.setUp();
  }

  Future<void> test_bareNewFailure_flagged() async => assertDiagnostics(
    'class DomainException implements Exception {} void f() { try {} catch (_) { throw DomainException(); } }',
    [lint(64, 38)],
  );
  Future<void> test_objectNewFailure_flagged() async => assertDiagnostics(
    'class DomainException implements Exception {} void f() { try {} on Object catch (_) { throw DomainException(); } }',
    [lint(64, 48)],
  );
  Future<void> test_exceptionNewFailure_flagged() async => assertDiagnostics(
    'class DomainException implements Exception {} void f() { try {} on Exception catch (_) { throw DomainException(); } }',
    [lint(64, 51)],
  );
  Future<void> test_typedCatch_allowed() async => assertNoDiagnostics(
    'class DomainException implements Exception {} void f() { try {} on FormatException catch (_) { throw DomainException(); } }',
  );
  Future<void> test_bareLog_allowed() async =>
      assertNoDiagnostics('void f() { try {} catch (e) { print(e); } }');
  Future<void> test_bareRethrow_allowed() async =>
      assertNoDiagnostics('void f() { try {} catch (_) { rethrow; } }');
}
