import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_build_context_fields.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'boundary_stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoBuildContextFieldsTest);
  });
}

@reflectiveTest
class NoBuildContextFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoBuildContextFields();
    super.setUp();
  }

  /// [needle] is the exact text of the reported type, first occurrence
  /// after the stubs.
  Future<void> flagged(String body, String needle) async {
    final s = withStubs(body);
    final at = s.source.indexOf(needle, s.bodyStart);
    await assertDiagnostics(s.source, [lint(at, needle.length)]);
  }

  Future<void> clean(String body) async =>
      assertNoDiagnostics(withStubs(body).source);

  Future<void> test_plain_class_field_flagged() => flagged(
    'class Holder { Holder(this.ctx); final BuildContext ctx; }',
    'BuildContext',
  );
  Future<void> test_nullable_field_flagged() =>
      flagged('class Holder { BuildContext? ctx; }', 'BuildContext?');
  Future<void> test_late_field_flagged() =>
      flagged('class Holder { late BuildContext ctx; }', 'BuildContext');
  Future<void> test_static_field_flagged() =>
      flagged('class Holder { static BuildContext? ctx; }', 'BuildContext?');
  Future<void> test_cubit_field_flagged() => flagged(
    'class BarCubit extends Cubit<int> { BuildContext? ctx; }',
    'BuildContext?',
  );
  Future<void> test_stateless_widget_field_flagged() => flagged('''
class V extends StatelessWidget {
  const V(this.ctx);
  final BuildContext ctx;
  Widget build(BuildContext context) => Leaf();
}
''', 'BuildContext');
  Future<void> test_mixin_field_flagged() =>
      flagged('mixin M { BuildContext? ctx; }', 'BuildContext?');

  Future<void> test_state_field_clean() => clean('''
class W extends StatefulWidget { const W(); }
class WState extends State<W> {
  BuildContext? saved;
  Widget build(BuildContext context) => Leaf();
}
''');
  Future<void> test_state_of_adapter_clean() => clean('''
class SA extends StatefulAdapterWidget { const SA(); }
class SAState extends State<SA> {
  late BuildContext saved;
  Widget build(BuildContext context) => Leaf();
}
''');
  Future<void> test_plain_field_clean() =>
      clean('class Holder { Holder(this.foo); final Foo foo; }');
  Future<void> test_parameter_and_local_clean() => clean('''
class Holder {
  void use(BuildContext context) {
    final BuildContext local = context;
  }
}
''');
}
