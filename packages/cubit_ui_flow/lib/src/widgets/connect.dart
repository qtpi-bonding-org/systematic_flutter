import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'adapter_scope.dart';

/// Rebuilds [builder] with a value selected from one Cubit's state.
///
/// [select] must be a static or top-level function. Its identity is the
/// memoization key, so a closure defeats caching. The builder runs again
/// only when the selected value changes by `==`.
///
/// The Cubit comes from [resolve], or from `context.read<C>()` if [resolve]
/// is null. It is resolved once, on the first build.
class Connect<C extends StateStreamable<S>, S, D> extends StatefulWidget {
  const Connect({
    required this.select,
    required this.builder,
    this.resolve,
    super.key,
  });

  final D Function(S state) select;
  final Widget Function(BuildContext context, D data, C cubit) builder;
  final C Function(BuildContext context)? resolve;

  @override
  State<Connect<C, S, D>> createState() => _ConnectState<C, S, D>();
}

class _ConnectState<C extends StateStreamable<S>, S, D>
    extends State<Connect<C, S, D>> {
  final AdapterScopeImpl _scope = AdapterScopeImpl();
  C? _cubit;

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit ??= widget.resolve?.call(context) ?? context.read<C>();
    final field = _scope.cubitField<S, D>(cubit, widget.select);
    return ValueListenableBuilder<D>(
      valueListenable: field,
      builder: (context, data, _) => widget.builder(context, data, cubit),
    );
  }
}

/// Two-Cubit variant of [Connect]. [select] receives both states and must be
/// a static or top-level function. The builder runs again only when the
/// combined value changes by `==`.
class Connect2<C1 extends StateStreamable<S1>, S1, C2 extends StateStreamable<S2>,
    S2, D> extends StatefulWidget {
  const Connect2({
    required this.select,
    required this.builder,
    this.resolve1,
    this.resolve2,
    super.key,
  });

  final D Function(S1 state1, S2 state2) select;
  final Widget Function(BuildContext context, D data, C1 cubit1, C2 cubit2)
      builder;
  final C1 Function(BuildContext context)? resolve1;
  final C2 Function(BuildContext context)? resolve2;

  @override
  State<Connect2<C1, S1, C2, S2, D>> createState() =>
      _Connect2State<C1, S1, C2, S2, D>();
}

/// Identity selector. Each instantiation is stored once in the State, so the
/// scope's memoization key stays the same across builds.
S _identity<S>(S state) => state;

class _Connect2State<C1 extends StateStreamable<S1>, S1,
    C2 extends StateStreamable<S2>, S2, D>
    extends State<Connect2<C1, S1, C2, S2, D>> {
  final AdapterScopeImpl _scope = AdapterScopeImpl();
  final S1 Function(S1) _id1 = _identity<S1>;
  final S2 Function(S2) _id2 = _identity<S2>;
  C1? _cubit1;
  C2? _cubit2;
  ValueListenable<D>? _combined;

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit1 = _cubit1 ??= widget.resolve1?.call(context) ?? context.read<C1>();
    final cubit2 = _cubit2 ??= widget.resolve2?.call(context) ?? context.read<C2>();
    final combined = _combined ??= _scope.combine2<S1, S2, D>(
      _scope.cubitField<S1, S1>(cubit1, _id1),
      _scope.cubitField<S2, S2>(cubit2, _id2),
      widget.select,
    );
    return ValueListenableBuilder<D>(
      valueListenable: combined,
      builder: (context, data, _) => widget.builder(context, data, cubit1, cubit2),
    );
  }
}
