import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/require_static_selector.dart';
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

  static const _connect = r"""
class Connect {
  Connect({Object? select});
}
class Connect2 {
  Connect2({Object? select});
}
class ConnectFor {
  ConnectFor({Object? select});
}
int topLevelSelector() => 1;
""";

  Future<void> test_flags_inline_closure_in_connect() async {
    const src = '$_connect\nfinal a = Connect(select: () => 1);\n';
    await assertDiagnostics(src, [
      lint(src.indexOf('Connect(select: () => 1)') + 16, 7),
    ]);
  }

  Future<void> test_flags_inline_closure_in_connect2() async {
    const src = '$_connect\nfinal a = Connect2(select: () => 1);\n';
    await assertDiagnostics(src, [
      lint(src.indexOf('Connect2(select: () => 1)') + 17, 7),
    ]);
  }

  Future<void> test_allows_tearoff_in_connect() async {
    await assertNoDiagnostics(
      '$_connect\nfinal a = Connect(select: topLevelSelector);\n'
      'final b = Connect2(select: topLevelSelector);\n',
    );
  }

  Future<void> test_ignores_connect_without_select() async {
    await assertNoDiagnostics('$_connect\nfinal a = Connect();\n');
  }

  Future<void> test_flags_inline_closure_in_connect_for() async {
    const src = '$_connect\nfinal a = ConnectFor(select: () => 1);\n';
    await assertDiagnostics(src, [
      lint(src.indexOf('ConnectFor(select: () => 1)') + 19, 7),
    ]);
  }

  Future<void> test_allows_tearoff_in_connect_for() async {
    await assertNoDiagnostics(
      '$_connect\nfinal a = ConnectFor(select: topLevelSelector);\n',
    );
  }
}
