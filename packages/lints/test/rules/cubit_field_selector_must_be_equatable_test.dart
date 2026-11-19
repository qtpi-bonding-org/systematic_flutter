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
""";

  Future<void> test_flags_list_literal_in_connect() async {
    const src = '$_connect\nfinal a = Connect(select: () => [1, 2]);\n';
    await assertDiagnostics(src, [lint(src.indexOf('[1, 2]'), 6)]);
  }

  Future<void> test_flags_record_literal_in_connect2() async {
    const src = '$_connect\nfinal a = Connect2(select: () => (1, 2));\n';
    await assertDiagnostics(src, [lint(src.indexOf('(1, 2)'), 6)]);
  }

  Future<void> test_allows_scalar_in_connect() async {
    await assertNoDiagnostics(
      '$_connect\nfinal a = Connect(select: () => 1);\n',
    );
  }

  Future<void> test_flags_list_literal_in_connect_for() async {
    const src = '$_connect\nfinal a = ConnectFor(select: () => [1, 2]);\n';
    await assertDiagnostics(src, [lint(src.indexOf('[1, 2]'), 6)]);
  }

  Future<void> test_allows_scalar_in_connect_for() async {
    await assertNoDiagnostics(
      '$_connect\nfinal a = ConnectFor(select: () => 1);\n',
    );
  }
}
