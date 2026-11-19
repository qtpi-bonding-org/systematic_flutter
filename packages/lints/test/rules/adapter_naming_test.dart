import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/adapter_naming.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'boundary_stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AdapterNamingTest);
  });
}

@reflectiveTest
class AdapterNamingTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AdapterNaming();
    super.setUp();
  }

  /// [name] is the reported class name token.
  Future<void> flagged(String body, String name) async {
    final s = withStubs(body);
    final at = s.source.indexOf(name, s.bodyStart);
    await assertDiagnostics(s.source, [lint(at, name.length)]);
  }

  Future<void> clean(String body) async =>
      assertNoDiagnostics(withStubs(body).source);

  Future<void> test_adapter_widget_without_suffix_flagged() => flagged(
    'class Foo2 extends AdapterWidget { const Foo2(); '
        'Widget build(BuildContext c) => Leaf(); }',
    'Foo2',
  );
  Future<void> test_cubit_adapter_without_suffix_flagged() => flagged(
    'class Foo2 extends CubitAdapter<FooCubit> { const Foo2(); '
        'Widget build(BuildContext c) => Leaf(); }',
    'Foo2',
  );
  Future<void> test_stateful_adapter_without_suffix_flagged() => flagged(
    'class Foo2 extends StatefulAdapterWidget { const Foo2(); }',
    'Foo2',
  );
  Future<void> test_multi_cubit_adapter_without_suffix_flagged() => flagged(
    'class Foo2 extends MultiCubitAdapter { const Foo2(); '
        'Widget build(BuildContext c) => Leaf(); }',
    'Foo2',
  );
  Future<void> test_adapter_with_suffix_clean() => clean(
    'class Foo2Adapter extends AdapterWidget { const Foo2Adapter(); '
    'Widget build(BuildContext c) => Leaf(); }',
  );
  Future<void> test_cubit_adapter_with_suffix_clean() => clean(
    'class Foo2Adapter extends CubitAdapter<FooCubit> { '
    'const Foo2Adapter(); Widget build(BuildContext c) => Leaf(); }',
  );
  Future<void> test_view_with_adapter_suffix_flagged() => flagged(
    'class Foo2Adapter extends StatelessWidget { const Foo2Adapter(); '
        'Widget build(BuildContext c) => Leaf(); }',
    'Foo2Adapter',
  );
  Future<void> test_stateful_view_with_adapter_suffix_flagged() => flagged(
    'class Foo2Adapter extends StatefulWidget { const Foo2Adapter(); }',
    'Foo2Adapter',
  );
  Future<void> test_plain_view_clean() => clean(
    'class Foo2 extends StatelessWidget { const Foo2(); '
    'Widget build(BuildContext c) => Leaf(); }',
  );
  Future<void> test_non_widget_adapter_clean() =>
      clean('class PaletteAdapter {}');
  Future<void> test_non_widget_plain_clean() => clean('class Plain {}');
}
