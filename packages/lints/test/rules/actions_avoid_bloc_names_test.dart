import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/actions_avoid_bloc_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ActionsAvoidBlocNamesTest);
  });
}

@reflectiveTest
class ActionsAvoidBlocNamesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ActionsAvoidBlocNames();
    super.setUp();
  }

  /// [name] is the reported member name token (its first occurrence).
  Future<void> flagged(String source, String name) async =>
      assertDiagnostics(source, [lint(source.indexOf(name), name.length)]);

  Future<void> test_method_close_flagged() =>
      flagged('abstract class FooActions { void close(); }', 'close');
  Future<void> test_method_emit_flagged() =>
      flagged('abstract class FooActions { void emit(); }', 'emit');
  Future<void> test_method_onChange_flagged() =>
      flagged('abstract class FooActions { void onChange(); }', 'onChange');
  Future<void> test_method_onError_flagged() =>
      flagged('abstract class FooActions { void onError(); }', 'onError');
  Future<void> test_method_addError_flagged() =>
      flagged('abstract class FooActions { void addError(); }', 'addError');
  Future<void> test_getter_state_flagged() =>
      flagged('abstract class FooActions { int get state; }', 'state');
  Future<void> test_getter_stream_flagged() =>
      flagged('abstract class FooActions { int get stream; }', 'stream');
  Future<void> test_getter_isClosed_flagged() =>
      flagged('abstract class FooActions { int get isClosed; }', 'isClosed');

  Future<void> test_banned_field_flagged() =>
      flagged('abstract class FooActions { int get state; }', 'state');

  Future<void> test_abstract_field_flagged() => flagged(
    'abstract class FooActions { abstract final int isClosed; }',
    'isClosed',
  );

  Future<void> test_interface_class_flagged() =>
      flagged('abstract interface class FooActions { void close(); }', 'close');

  Future<void> test_ordinary_members_clean() => assertNoDiagnostics('''
abstract class FooActions {
  void save();
  Future<void> load(int id);
  int get count;
}
''');

  Future<void> test_non_actions_class_clean() => assertNoDiagnostics(
    'abstract class FooService { void close(); int get state; }',
  );

  Future<void> test_concrete_actions_class_clean() =>
      assertNoDiagnostics('class FooActions { void close() {} }');

  Future<void> test_mixin_member_flagged() =>
      flagged('mixin FooActions { void close(); }', 'close');
  Future<void> test_mixin_getter_flagged() =>
      flagged('mixin FooActions { int get state; }', 'state');
  Future<void> test_mixin_class_member_flagged() =>
      flagged('mixin class FooActions { void emit() {} }', 'emit');
  Future<void> test_non_abstract_interface_class_flagged() =>
      flagged('interface class FooActions { void close() {} }', 'close');
  Future<void> test_mixin_ordinary_members_clean() =>
      assertNoDiagnostics('mixin FooActions { void save(); }');
  Future<void> test_non_actions_mixin_clean() =>
      assertNoDiagnostics('mixin FooService { void close(); }');
}
