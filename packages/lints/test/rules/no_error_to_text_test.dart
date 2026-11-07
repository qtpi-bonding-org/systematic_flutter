import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_error_to_text.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() =>
    defineReflectiveSuite(() => defineReflectiveTests(NoErrorToTextTest));

@reflectiveTest
class NoErrorToTextTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoErrorToText();
    super.setUp();
  }

  Future<void> test_exceptionToString_flagged() async {
    const c = 'void f(Exception e) { e.toString(); }';
    await assertDiagnostics(c, [lint(c.indexOf('e.toString()'), 12)]);
  }

  Future<void> test_errorInterpolation_flagged() async {
    const c = 'void f(Error e) { "\$e"; }';
    await assertDiagnostics(c, [lint(c.indexOf('\$e'), 2)]);
  }

  Future<void> test_customException_flagged() async {
    const c = 'class E implements Exception {}\nvoid f(E e) { "\${e}"; }';
    await assertDiagnostics(c, [lint(c.indexOf('\${e}'), 4)]);
  }

  Future<void> test_objectCatchLimitation_notFlagged() async {
    await assertNoDiagnostics('void f(Object e) { e.toString(); "\${e}"; }');
  }

  Future<void> test_int_notFlagged() async {
    await assertNoDiagnostics('void f(int e) { e.toString(); "\$e"; }');
  }

  Future<void> test_loggerArgument_withoutOption_flagged() async {
    const c =
        'class Log { void error(Object x) {} }\nvoid f(Exception e, Log log) { log.error(e.toString()); }';
    await assertDiagnostics(c, [lint(c.indexOf('e.toString()'), 12)]);
  }

  Future<void> test_errorToStringWithArgs_notFlagged() async {
    await assertNoDiagnostics('void f(Exception e) { e.toString; }');
  }
}
