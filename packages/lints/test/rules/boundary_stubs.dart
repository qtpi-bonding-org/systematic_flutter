/// Source stubs for the boundary rules' tests. Matching in the rules is by
/// type name, so these stand in for flutter, bloc, get_it and cubit_ui_flow.
const boundaryStubs = r'''
class BuildContext {}
abstract class Widget { const Widget(); }
class Leaf extends Widget {}
abstract class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context);
}
abstract class StatefulWidget extends Widget {
  const StatefulWidget();
}
abstract class InheritedWidget extends Widget {
  const InheritedWidget();
}
abstract class State<T extends StatefulWidget> {
  BuildContext get context => throw 0;
  Widget build(BuildContext context);
}
extension ContextX on BuildContext {
  T read<T>() => throw 0;
  T watch<T>() => throw 0;
  R select<T, R>(R Function(T) f) => throw 0;
}
class Provider {
  static T of<T>(BuildContext c) => throw 0;
}
class BlocProvider extends Widget {
  BlocProvider();
  static T of<T>(BuildContext c) => throw 0;
}
class RepositoryProvider extends Widget {
  RepositoryProvider();
  static T of<T>(BuildContext c) => throw 0;
}
class ScopeProvider {
  static T of<T>(BuildContext c) => throw 0;
  static T? maybeOf<T>(BuildContext c) => throw 0;
}
class BlocBuilder extends Widget { BlocBuilder(); }
class BlocListener extends Widget { BlocListener(); }
class BlocConsumer extends Widget { BlocConsumer(); }
class BlocSelector extends Widget { BlocSelector(); }
class MultiBlocProvider extends Widget { MultiBlocProvider(); }
class UiFlowListener extends Widget { UiFlowListener(); }
class UiFlowStateListener extends Widget { UiFlowStateListener(); }
class Connect extends Widget { Connect({Object? select}); }
class Connect2 extends Widget { Connect2({Object? select}); }
abstract class AdapterWidget extends StatelessWidget {
  const AdapterWidget();
}
abstract class StatefulAdapterWidget extends StatefulWidget {
  const StatefulAdapterWidget();
}
abstract class CubitAdapter<C> extends StatelessWidget {
  const CubitAdapter();
}
abstract class MultiCubitAdapter extends StatelessWidget {
  const MultiCubitAdapter();
}
abstract class BlocBase<S> {}
class Cubit<S> extends BlocBase<S> {}
class Bloc<E, S> extends BlocBase<S> {}
class FooCubit extends Cubit<int> {}
class FooBloc extends Bloc<int, int> {}
abstract class AppScope {}
class MyScope extends AppScope {}
class Foo {}
class GetIt {
  static final GetIt I = GetIt();
  T call<T>() => throw 0;
}
GetIt get getIt => GetIt.I;
''';

/// [imports] + stubs + [body], and the offset where [body] starts.
({String source, int bodyStart}) withStubs(String body, {String imports = ''}) {
  final prefix = '$imports$boundaryStubs';
  return (source: '$prefix$body', bodyStart: prefix.length);
}
