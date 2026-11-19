import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/backend_access_only_in_adapters.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'boundary_stubs.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BackendAccessOnlyInAdaptersTest);
    defineReflectiveTests(BackendAccessCompositionRootTest);
    defineReflectiveTests(BackendAccessOutsideCompositionRootTest);
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
  Future<void> test_ConnectFor_flagged() =>
      flagged(view('ConnectFor();'), ['ConnectFor()']);

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
  Future<void> test_context_extension_implicit_read_flagged() => flagged(
    'extension Ext on BuildContext { Foo f() => read<Foo>(); }',
    ['read<Foo>()'],
  );
  Future<void> test_context_extension_implicit_watch_flagged() => flagged(
    'extension Ext on BuildContext { Foo f() => watch<Foo>(); }',
    ['watch<Foo>()'],
  );
  Future<void> test_context_extension_implicit_select_flagged() => flagged(
    'extension Ext on BuildContext { int f() => select<Foo, int>((x) => 1); }',
    ['select<Foo, int>((x) => 1)'],
  );
  Future<void> test_non_context_extension_implicit_read_clean() => clean(
    'class Box { T read<T>() => throw 0; }\n'
    'extension Ext on Box { Foo f() => read<Foo>(); }',
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
  Future<void> test_top_level_context_function_any_return_flagged() => flagged(
    '''
Foo load(BuildContext context) {
  return context.read<Foo>();
}
''',
    ['context.read<Foo>()'],
  );
  Future<void> test_top_level_void_context_arrow_function_flagged() =>
      flagged('void del(BuildContext c) => c.read<Foo>();', ['c.read<Foo>()']);
  Future<void> test_top_level_function_without_context_clean() => clean('''
Foo make() => getIt<Foo>();
void useCubit(FooCubit c) {}
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

  // is checks and patterns

  Future<void> test_is_cubit_flagged() =>
      flagged(view('final b = Object() is FooCubit;'), ['FooCubit']);
  Future<void> test_is_not_bloc_flagged() =>
      flagged(view('final b = Object() is! FooBloc;'), ['FooBloc']);
  Future<void> test_is_scope_flagged() =>
      flagged(view('final b = Object() is MyScope;'), ['MyScope']);
  Future<void> test_is_plain_clean() =>
      clean(view('final b = Object() is Foo;'));
  Future<void> test_is_cubit_in_adapter_clean() =>
      clean(adapter('final b = Object() is FooCubit;'));
  Future<void> test_declared_variable_pattern_flagged() => flagged(
    view('final o = Object(); switch (o) { case FooCubit c: break; default: }'),
    ['FooCubit'],
  );
  Future<void> test_if_case_object_pattern_flagged() => flagged(
    view('final o = Object(); if (o case FooCubit()) {}'),
    ['FooCubit'],
  );
  Future<void> test_pattern_in_adapter_clean() =>
      clean(adapter('final o = Object(); if (o case FooCubit()) {}'));
  Future<void> test_pattern_plain_type_clean() =>
      clean(view('final o = Object(); if (o case Foo()) {}'));

  // type arguments and function types

  static String viewField(String decl) =>
      '''
class V extends StatelessWidget {
  const V(this.f);
  $decl
  Widget build(BuildContext context) => Leaf();
}
''';

  Future<void> test_list_of_cubit_field_flagged() =>
      flagged(viewField('final List<FooCubit> f;'), ['FooCubit']);
  Future<void> test_map_of_cubit_field_flagged() =>
      flagged(viewField('final Map<String, FooCubit> f;'), ['FooCubit']);
  Future<void> test_future_of_cubit_field_flagged() =>
      flagged(viewField('final Future<FooCubit> f;'), ['FooCubit']);
  Future<void> test_nested_generic_field_flagged() =>
      flagged(viewField('final List<Map<int, FooCubit>> f;'), ['FooCubit']);
  Future<void> test_function_type_parameter_field_flagged() =>
      flagged(viewField('final void Function(FooCubit) f;'), ['FooCubit']);
  Future<void> test_function_type_return_field_flagged() =>
      flagged(viewField('final FooCubit Function() f;'), ['FooCubit']);
  Future<void> test_list_of_scope_field_flagged() =>
      flagged(viewField('final List<MyScope> f;'), ['MyScope']);
  Future<void> test_list_of_plain_field_clean() =>
      clean(viewField('final List<Foo> f;'));
  Future<void> test_function_type_plain_field_clean() =>
      clean(viewField('final void Function(Foo) f;'));
  Future<void> test_generic_parameter_flagged() => flagged(
    '''
class V extends StatelessWidget {
  const V();
  void use(List<FooCubit> cubits) {}
  Widget build(BuildContext context) => Leaf();
}
''',
    ['FooCubit'],
  );
  Future<void> test_future_return_type_flagged() => flagged(
    '''
class V extends StatelessWidget {
  const V();
  Future<FooCubit> load() async => throw 0;
  Widget build(BuildContext context) => Leaf();
}
''',
    ['FooCubit'],
  );
  Future<void> test_cast_to_generic_cubit_flagged() =>
      flagged(view('final c = (Object() as List<FooCubit>);'), ['FooCubit']);
  Future<void> test_generic_data_path_field_flagged() {
    newFile('$testPackageLibPath/data/repo.dart', 'class Repo {}');
    return flagged(viewField('final List<Repo> f;'), [
      'Repo',
    ], imports: "import 'package:test/data/repo.dart';\n");
  }

  Future<void> test_generic_cubit_in_adapter_clean() => clean('''
class VAdapter extends AdapterWidget {
  const VAdapter(this.f);
  final List<FooCubit> f;
  Widget build(BuildContext context) => Leaf();
}
''');

  // non-widget classes holding cubits or scopes

  Future<void> test_view_data_with_cubit_flagged() => flagged(
    'class ViewData { const ViewData(this.cubit); final FooCubit cubit; }',
    ['FooCubit'],
  );
  Future<void> test_plain_class_generic_scope_field_flagged() =>
      flagged('class Holder { final List<MyScope> scopes = []; }', ['MyScope']);
  Future<void> test_plain_class_function_type_cubit_flagged() => flagged(
    'class Holder { Holder(this.f); final void Function(FooBloc) f; }',
    ['FooBloc'],
  );
  Future<void> test_plain_class_plain_field_clean() =>
      clean('class Vd { const Vd(this.foo); final Foo foo; }');
  Future<void> test_plain_class_data_path_field_clean() {
    newFile('$testPackageLibPath/data/repo.dart', 'class Repo {}');
    return clean(
      'class Service { const Service(this.repo); final Repo repo; }',
      imports: "import 'package:test/data/repo.dart';\n",
    );
  }

  Future<void> test_unannotated_service_holding_cubit_flagged() => flagged(
    'class Service { Service(this.c); final FooCubit c; }',
    ['FooCubit'],
  );
  Future<void> test_adapter_helper_class_holding_cubit_clean() => clean(
    'const adapterHelper = Object(); @adapterHelper class Helper { Helper(this.c); final FooCubit c; }',
  );
  Future<void> test_action_subclass_holding_cubit_clean() => clean(
    'class OpenAction extends Action<int> { OpenAction(this.c); final FooCubit c; }',
  );
  Future<void> test_service_with_getit_clean() => clean(
    'class Service { final GetIt g = GetIt.I; Foo load() => getIt<Foo>(); }',
  );
  Future<void> test_cubit_with_cubit_field_clean() => clean(
    'class BarCubit extends Cubit<int> { BarCubit(this.other); final FooCubit other; }',
  );
  Future<void> test_bloc_with_scope_field_clean() => clean(
    'class BarBloc extends Bloc<int, int> { final MyScope scope = MyScope(); }',
  );
  Future<void> test_scope_with_cubit_field_clean() => clean(
    'class OtherScope extends AppScope { final FooCubit c = FooCubit(); }',
  );
  Future<void> test_scope_with_list_of_cubits_clean() => clean(
    'class OtherScope extends AppScope { final List<FooCubit> c = []; }',
  );

  // top-level functions with a BuildContext parameter

  Future<void> test_context_function_cubit_parameter_flagged() => flagged(
    'void confirm(BuildContext context, FooCubit cubit) {}',
    ['FooCubit'],
  );
  Future<void> test_adapter_helper_annotation_exempts_function() => clean('''
const adapterHelper = Object();
@adapterHelper
Future<void> confirmAndDelete(
  BuildContext context,
  FooCubit cubit,
  String id,
) async {
  context.read<Foo>();
}
''');
  Future<void> test_adapter_helper_class_annotation_exempts_function() =>
      clean('''
class AdapterHelper { const AdapterHelper(); }
@AdapterHelper()
void confirm(BuildContext context, FooCubit cubit) {
  context.watch<Foo>();
}
''');
  Future<void> test_adapter_helper_exempts_widget_function() => clean('''
const adapterHelper = Object();
@adapterHelper
Widget w(BuildContext context) {
  context.read<Foo>();
  return Leaf();
}
''');
  Future<void> test_adapter_helper_still_bans_getit() => flagged(
    '''
const adapterHelper = Object();
@adapterHelper
void f(BuildContext context) {
  GetIt.I;
}
''',
    ['GetIt'],
  );
  Future<void> test_other_annotation_does_not_exempt() => flagged(
    '''
const keep = Object();
@keep
void f(BuildContext context) => context.read<Foo>();
''',
    ['context.read<Foo>()'],
  );

  // prefixed and aliased calls

  static String prefixedView(String statement) =>
      '''
import 'package:test/stubs.dart' as p;
class V extends p.StatelessWidget {
  const V();
  p.Widget build(p.BuildContext context) {
    $statement
    return p.Leaf();
  }
}
''';

  Future<void> prefixed(String statement, String needle) async {
    newFile('$testPackageLibPath/stubs.dart', boundaryStubs);
    final source = prefixedView(statement);
    await assertDiagnostics(source, [
      lint(source.indexOf(needle), needle.length),
    ]);
  }

  Future<void> test_prefixed_provider_of_flagged() => prefixed(
    'p.Provider.of<p.Foo>(context);',
    'p.Provider.of<p.Foo>(context)',
  );
  Future<void> test_prefixed_bloc_provider_of_flagged() => prefixed(
    'p.BlocProvider.of<p.FooCubit>(context);',
    'p.BlocProvider.of<p.FooCubit>(context)',
  );
  Future<void> test_prefixed_scope_provider_maybe_of_flagged() => prefixed(
    'p.ScopeProvider.maybeOf<p.MyScope>(context);',
    'p.ScopeProvider.maybeOf<p.MyScope>(context)',
  );
  Future<void> test_prefixed_getit_flagged() => prefixed('p.GetIt.I;', 'GetIt');
  Future<void> test_prefixed_getit_function_flagged() =>
      prefixed('p.getIt<p.Foo>();', 'getIt');
  Future<void> test_aliased_provider_of_flagged() => flagged(
    'typedef Prov = Provider;\n${view('Prov.of<Foo>(context);')}',
    ['Prov.of<Foo>(context)'],
  );
  Future<void> test_aliased_getit_flagged() => flagged(view('Locator.I;'), [
    'Locator',
  ], imports: 'typedef Locator = GetIt;\n');

  // top-level variables

  Future<void> test_top_level_cubit_variable_flagged() =>
      flagged('final appCubit = FooCubit();', ['appCubit']);
  Future<void> test_top_level_late_cubit_variable_flagged() =>
      flagged('late FooCubit lateCubit;', ['lateCubit']);
  Future<void> test_top_level_scope_variable_flagged() =>
      flagged('final appScope = MyScope();', ['appScope']);
  Future<void> test_top_level_list_of_cubits_flagged() =>
      flagged('final List<FooCubit> cubits = [];', ['cubits']);
  Future<void> test_top_level_plain_variable_clean() =>
      clean('final foo = Foo();');
}

@reflectiveTest
class BackendAccessCompositionRootTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = BackendAccessOnlyInAdapters(compositionRootPaths: const ['lib/']);
    super.setUp();
  }

  static const _app = '''
class MyApp extends StatefulWidget {
  const MyApp();
}
class _MyAppState extends State<MyApp> {
  Widget build(BuildContext context) {
    getIt<Foo>();
    ScopeProvider.of<MyScope>(context);
    final f = () { context.read<Foo>(); return Leaf(); };
    return f();
  }
}
''';

  Future<void> test_widget_and_state_in_composition_root_clean() =>
      assertNoDiagnostics(withStubs(_app).source);
}

@reflectiveTest
class BackendAccessOutsideCompositionRootTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = BackendAccessOnlyInAdapters(
      compositionRootPaths: const ['lib/elsewhere/'],
    );
    super.setUp();
  }

  Future<void> test_same_widget_outside_is_flagged() async {
    final s = withStubs(BackendAccessCompositionRootTest._app);
    await assertDiagnostics(s.source, [
      lint(s.source.indexOf('getIt<Foo>', s.bodyStart), 'getIt'.length),
      lint(
        s.source.indexOf('ScopeProvider.of<MyScope>(context)'),
        'ScopeProvider.of<MyScope>(context)'.length,
      ),
      lint(
        s.source.indexOf('context.read<Foo>()'),
        'context.read<Foo>()'.length,
      ),
    ]);
  }
}
