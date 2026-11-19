import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/actions_return_void.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ActionsReturnVoidTest);
  });
}

@reflectiveTest
class ActionsReturnVoidTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ActionsReturnVoid();
    super.setUp();
  }

  /// [name] is the reported member name token (its first occurrence).
  Future<void> flagged(String source, String name) async =>
      assertDiagnostics(source, [lint(source.indexOf(name), name.length)]);

  Future<void> test_int_return_flagged() =>
      flagged('abstract class FooActions { int load(); }', 'load');
  Future<void> test_future_int_flagged() =>
      flagged('abstract class FooActions { Future<int> save(); }', 'save');
  Future<void> test_stream_flagged() => flagged(
    'abstract class FooActions { Stream<void> watch(); }',
    'watch',
  );
  Future<void> test_future_or_void_flagged() => flagged(
    'import "dart:async";\nabstract class FooActions { FutureOr<void> run(); }',
    'run',
  );
  Future<void> test_nullable_future_void_flagged() => flagged(
    'abstract class FooActions { Future<void>? run(); }',
    'run',
  );
  Future<void> test_implicit_dynamic_flagged() =>
      flagged('abstract class FooActions { save(); }', 'save');
  Future<void> test_getter_flagged() =>
      flagged('abstract class FooActions { int get count; }', 'count');
  Future<void> test_abstract_field_flagged() => flagged(
    'abstract class FooActions { abstract final int total; }',
    'total',
  );
  Future<void> test_interface_class_flagged() =>
      flagged('abstract interface class FooActions { int load(); }', 'load');
  Future<void> test_plain_interface_class_flagged() =>
      flagged('interface class FooActions { int load() => 1; }', 'load');
  Future<void> test_mixin_flagged() =>
      flagged('mixin FooActions { int load(); }', 'load');
  Future<void> test_mixin_class_flagged() =>
      flagged('mixin class FooActions { int load() => 1; }', 'load');

  Future<void> test_void_and_future_void_clean() => assertNoDiagnostics('''
abstract class FooActions {
  void save();
  Future<void> load(int id);
  set value(int v);
}
''');
  Future<void> test_mixin_void_clean() => assertNoDiagnostics(
    'mixin FooActions { void save(); Future<void> x(); }',
  );
  Future<void> test_static_member_clean() => assertNoDiagnostics(
    'abstract class FooActions { static int make() => 1; void save(); }',
  );
  Future<void> test_non_actions_class_clean() =>
      assertNoDiagnostics('abstract class FooService { int load(); }');
  Future<void> test_concrete_actions_class_clean() =>
      assertNoDiagnostics('class FooActions { int load() => 1; }');
}
