import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/backend_access_only_in_adapters.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'boundary_stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BackendAccessOnlyInAdaptersTest);
  });
}

@reflectiveTest
class BackendAccessOnlyInAdaptersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = BackendAccessOnlyInAdapters();
    super.setUp();
  }

  /// Each needle is the exact text of a reported node, searched in order
  /// from the start of [body].
  Future<void> flagged(
    String body,
    List<String> needles, {
    String imports = '',
  }) async {
    final s = withStubs(body, imports: imports);
    var from = s.bodyStart;
    final offsets = <int>[];
    for (final needle in needles) {
      final at = s.source.indexOf(needle, from);
      if (at < 0) throw StateError('needle not found: $needle');
      offsets.add(at);
      from = at + 1;
    }
    final expected = [
      for (var i = 0; i < needles.length; i++)
        lint(offsets[i], needles[i].length),
    ];
    await assertDiagnostics(s.source, expected);
  }

  Future<void> clean(String body, {String imports = ''}) async =>
      assertNoDiagnostics(withStubs(body, imports: imports).source);

  static String view(String statement) =>
      '''
class V extends StatelessWidget {
  const V();
  Widget build(BuildContext context) {
    $statement
    return Leaf();
  }
}
''';

  static String adapter(String statement) =>
      '''
class VAdapter extends CubitAdapter<FooCubit> {
  const VAdapter();
  Widget build(BuildContext context) {
    $statement
    return Leaf();
  }
}
''';

  // context.read / watch / select

  Future<void> test_context_read_flagged() =>
      flagged(view('context.read<Foo>();'), ['context.read<Foo>()']);
  Future<void> test_context_watch_flagged() =>
      flagged(view('context.watch<Foo>();'), ['context.watch<Foo>()']);
  Future<void> test_context_select_flagged() => flagged(
    view('context.select<Foo, int>((f) => 1);'),
    ['context.select<Foo, int>((f) => 1)'],
  );
  Future<void> test_non_context_read_clean() => clean(
    view('final o = _O(); o.read<Foo>();') +
        'class _O { T read<T>() => throw 0; }',
  );

  // .of lookups

  Future<void> test_provider_of_flagged() => flagged(
    view('Provider.of<Foo>(context);'),
    ['Provider.of<Foo>(context)'],
  );
  Future<void> test_bloc_provider_of_flagged() => flagged(
    view('BlocProvider.of<FooCubit>(context);'),
    ['BlocProvider.of<FooCubit>(context)'],
  );
  Future<void> test_repository_provider_of_flagged() => flagged(
    view('RepositoryProvider.of<Foo>(context);'),
    ['RepositoryProvider.of<Foo>(context)'],
  );
  Future<void> test_scope_provider_of_flagged() => flagged(
    view('ScopeProvider.of<MyScope>(context);'),
    ['ScopeProvider.of<MyScope>(context)'],
  );
  Future<void> test_scope_provider_maybe_of_flagged() => flagged(
    view('ScopeProvider.maybeOf<MyScope>(context);'),
    ['ScopeProvider.maybeOf<MyScope>(context)'],
  );

  // bloc widgets

  Future<void> test_BlocBuilder_flagged() =>
      flagged(view('BlocBuilder();'), ['BlocBuilder()']);
  Future<void> test_BlocListener_flagged() =>
      flagged(view('BlocListener();'), ['BlocListener()']);
  Future<void> test_BlocConsumer_flagged() =>
      flagged(view('BlocConsumer();'), ['BlocConsumer()']);
  Future<void> test_BlocSelector_flagged() =>
      flagged(view('BlocSelector();'), ['BlocSelector()']);
  Future<void> test_BlocProvider_flagged() =>
      flagged(view('BlocProvider();'), ['BlocProvider()']);
  Future<void> test_MultiBlocProvider_flagged() =>
      flagged(view('MultiBlocProvider();'), ['MultiBlocProvider()']);
  Future<void> test_RepositoryProvider_flagged() =>
      flagged(view('RepositoryProvider();'), ['RepositoryProvider()']);
  Future<void> test_UiFlowListener_flagged() =>
      flagged(view('UiFlowListener();'), ['UiFlowListener()']);
  Future<void> test_UiFlowStateListener_flagged() =>
      flagged(view('UiFlowStateListener();'), ['UiFlowStateListener()']);
  Future<void> test_Connect_flagged() =>
      flagged(view('Connect();'), ['Connect()']);
  Future<void> test_Connect2_flagged() =>
      flagged(view('Connect2();'), ['Connect2()']);

  Future<void> test_plain_widget_creation_clean() => clean(view('Leaf();'));

  // GetIt

  Future<void> test_getit_in_view_flagged() =>
      flagged(view('GetIt.I;'), ['GetIt']);
  Future<void> test_lowercase_getit_flagged() =>
      flagged(view('getIt<Foo>();'), ['getIt']);
  Future<void> test_getit_in_adapter_still_flagged() =>
      flagged(adapter('GetIt.I;'), ['GetIt']);
  Future<void> test_getit_type_in_view_flagged() => flagged(
    '''
class V extends StatelessWidget {
  const V();
  Widget build(BuildContext context) {
    GetIt? g;
    return Leaf();
  }
}
''',
    ['GetIt'],
  );
  Future<void> test_getit_in_non_widget_service_clean() => clean('''
class Service {
  Foo load() => getIt<Foo>();
  GetIt get locator => GetIt.I;
}
''');

  // exempt adapters

  Future<void> test_adapter_context_read_clean() =>
      clean(adapter('context.read<FooCubit>();'));
  Future<void> test_adapter_bloc_widgets_and_connect_clean() =>
      clean(adapter('BlocBuilder(); Connect(); UiFlowListener();'));
  Future<void> test_adapter_scope_lookup_clean() =>
      clean(adapter('ScopeProvider.of<MyScope>(context);'));
  Future<void> test_adapter_with_cubit_field_clean() => clean('''
class VAdapter extends AdapterWidget {
  const VAdapter(this.cubit);
  final FooCubit cubit;
  Widget build(BuildContext context) => Leaf();
}
''');
  Future<void> test_stateful_adapter_state_clean() => clean('''
class SA extends StatefulAdapterWidget {
  const SA();
}
class SAState extends State<SA> {
  Widget build(BuildContext context) {
    context.read<FooCubit>();
    return Leaf();
  }
}
''');
  Future<void> test_multi_cubit_adapter_clean() => clean('''
class MAdapter extends MultiCubitAdapter {
  const MAdapter();
  Widget build(BuildContext context) {
    context.watch<FooCubit>();
    return Leaf();
  }
}
''');

  // State of a view

  Future<void> test_state_of_view_flagged() => flagged(
    '''
class W extends StatefulWidget {
  const W();
}
class WState extends State<W> {
  Widget build(BuildContext context) {
    context.read<Foo>();
    return Leaf();
  }
}
''',
    ['context.read<Foo>()'],
  );

  // extensions and top-level functions

  Future<void> test_context_extension_flagged() => flagged(
    'extension Ext on BuildContext { Foo f() => this.read<Foo>(); }',
    ['this.read<Foo>()'],
  );
  Future<void> test_top_level_widget_function_flagged() => flagged(
    '''
Widget build2(BuildContext context) {
  context.read<Foo>();
  return Leaf();
}
''',
    ['context.read<Foo>()'],
  );
  Future<void> test_top_level_non_widget_function_clean() => clean('''
Foo load(BuildContext context) {
  return context.read<Foo>();
}
''');
  Future<void> test_top_level_widget_function_closure_flagged() => flagged(
    '''
Widget build2(BuildContext context) {
  void f() { context.watch<Foo>(); }
  return Leaf();
}
''',
    ['context.watch<Foo>()'],
  );

  // types

  Future<void> test_cast_to_cubit_flagged() =>
      flagged(view('final c = (Object() as FooCubit);'), ['FooCubit']);
  Future<void> test_cast_to_bloc_flagged() =>
      flagged(view('final c = (Object() as FooBloc);'), ['FooBloc']);
  Future<void> test_cast_to_scope_flagged() =>
      flagged(view('final c = (Object() as MyScope);'), ['MyScope']);
  Future<void> test_cast_to_plain_clean() =>
      clean(view('final c = (Object() as Foo);'));
  Future<void> test_cubit_field_flagged() => flagged(
    '''
class V extends StatelessWidget {
  const V(this.cubit);
  final FooCubit cubit;
  Widget build(BuildContext context) => Leaf();
}
''',
    ['FooCubit'],
  );
  Future<void> test_scope_parameter_flagged() => flagged(
    '''
class V extends StatelessWidget {
  const V();
  void use(MyScope scope) {}
  Widget build(BuildContext context) => Leaf();
}
''',
    ['MyScope'],
  );
  Future<void> test_plain_field_clean() => clean('''
class V extends StatelessWidget {
  const V(this.foo);
  final Foo foo;
  Widget build(BuildContext context) => Leaf();
}
''');
  Future<void> test_data_path_field_flagged() {
    newFile('$testPackageLibPath/data/repo.dart', 'class Repo {}');
    return flagged(
      '''
class V extends StatelessWidget {
  const V(this.repo);
  final Repo repo;
  Widget build(BuildContext context) => Leaf();
}
''',
      ['Repo'],
      imports: "import 'package:test/data/repo.dart';\n",
    );
  }

  Future<void> test_infrastructure_path_parameter_flagged() {
    newFile('$testPackageLibPath/infrastructure/clock.dart', 'class Clock {}');
    return flagged(
      '''
class V extends StatelessWidget {
  const V();
  void use(Clock clock) {}
  Widget build(BuildContext context) => Leaf();
}
''',
      ['Clock'],
      imports: "import 'package:test/infrastructure/clock.dart';\n",
    );
  }

  Future<void> test_other_path_field_clean() {
    newFile('$testPackageLibPath/ui/thing.dart', 'class Thing {}');
    return clean('''
class V extends StatelessWidget {
  const V(this.thing);
  final Thing thing;
  Widget build(BuildContext context) => Leaf();
}
''', imports: "import 'package:test/ui/thing.dart';\n");
  }
}
