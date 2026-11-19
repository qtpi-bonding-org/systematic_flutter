import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'adapter_scope.dart';

/// Test hook that observes [Connect], [Connect2] and [ConnectFor] builder runs.
///
/// Install an instance in a test to count builder runs per `debugLabel`. It is
/// null by default, so the hook is a no-op. Set [instance] back to null in
/// `tearDown`.
class ConnectObserver {
  /// The active observer, or null (the default) for no observation.
  static ConnectObserver? instance;

  /// Called just before a Connect builder runs, with that widget's
  /// `debugLabel`. Does nothing by default.
  void onBuild(String? debugLabel) {}
}

/// Rebuilds [builder] with a value selected from one Cubit's state.
///
/// [select] must be a static or top-level function. Its identity is the
/// memoization key, so a closure defeats caching. The builder runs again
/// only when the selected value changes by `==`.
///
/// The Cubit is resolved on every build: from [resolve], or from
/// `context.read<C>()` if [resolve] is null. When the resolved Cubit or
/// [select] changes, the old subscription is released and a new one is
/// created, so a Connect follows a swapped provider or a changed selection
/// without being re-keyed.
///
/// [debugLabel] is reported to [ConnectObserver] on each builder run.
class Connect<C extends StateStreamable<S>, S, D> extends StatefulWidget {
  const Connect({
    required this.select,
    required this.builder,
    this.resolve,
    this.debugLabel,
    super.key,
  });

  final D Function(S state) select;
  final Widget Function(BuildContext context, D data, C cubit) builder;
  final C Function(BuildContext context)? resolve;
  final String? debugLabel;

  @override
  State<Connect<C, S, D>> createState() => _ConnectState<C, S, D>();
}

class _ConnectState<C extends StateStreamable<S>, S, D>
    extends State<Connect<C, S, D>> {
  final AdapterScopeImpl _scope = AdapterScopeImpl();
  C? _cubit;
  D Function(S)? _select;
  ValueListenable<D>? _field;

  /// Cubit resolution happens in [build], so there is nothing to do when
  /// dependencies change; this only keeps the lifecycle explicit.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = widget.resolve?.call(context) ?? context.read<C>();
    var field = _field;
    if (field == null ||
        !identical(cubit, _cubit) ||
        widget.select != _select) {
      final oldCubit = _cubit;
      final oldSelect = _select;
      if (oldCubit != null && oldSelect != null) {
        _scope.release((oldCubit, oldSelect));
      }
      field = _scope.cubitField<S, D>(cubit, widget.select);
      _field = field;
      _cubit = cubit;
      _select = widget.select;
    }
    return ValueListenableBuilder<D>(
      valueListenable: field,
      builder: (context, data, _) {
        ConnectObserver.instance?.onBuild(widget.debugLabel);
        return widget.builder(context, data, cubit);
      },
    );
  }
}

/// Two-Cubit variant of [Connect]. [select] receives both states and must be
/// a static or top-level function. The builder runs again only when the
/// combined value changes by `==`.
///
/// Both Cubits are resolved on every build. When either Cubit or [select]
/// changes, the old combined value and its two field subscriptions are
/// released and rebuilt.
///
/// [debugLabel] is reported to [ConnectObserver] on each builder run.
class Connect2<C1 extends StateStreamable<S1>, S1, C2 extends StateStreamable<S2>,
    S2, D> extends StatefulWidget {
  const Connect2({
    required this.select,
    required this.builder,
    this.resolve1,
    this.resolve2,
    this.debugLabel,
    super.key,
  });

  final D Function(S1 state1, S2 state2) select;
  final Widget Function(BuildContext context, D data, C1 cubit1, C2 cubit2)
      builder;
  final C1 Function(BuildContext context)? resolve1;
  final C2 Function(BuildContext context)? resolve2;
  final String? debugLabel;

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
  D Function(S1, S2)? _select;
  ValueListenable<S1>? _field1;
  ValueListenable<S2>? _field2;
  ValueListenable<D>? _combined;

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  /// Releases the stored combined value, then its two field subscriptions.
  /// The combined entry goes first because it listens to the fields.
  void _releaseStored() {
    final c1 = _cubit1;
    final c2 = _cubit2;
    final select = _select;
    final f1 = _field1;
    final f2 = _field2;
    if (c1 == null || c2 == null || select == null || f1 == null || f2 == null) {
      return;
    }
    _scope.release((f1, f2, select));
    _scope.release((c1, _id1));
    _scope.release((c2, _id2));
  }

  @override
  Widget build(BuildContext context) {
    final cubit1 = widget.resolve1?.call(context) ?? context.read<C1>();
    final cubit2 = widget.resolve2?.call(context) ?? context.read<C2>();
    var combined = _combined;
    if (combined == null ||
        !identical(cubit1, _cubit1) ||
        !identical(cubit2, _cubit2) ||
        widget.select != _select) {
      _releaseStored();
      final field1 = _scope.cubitField<S1, S1>(cubit1, _id1);
      final field2 = _scope.cubitField<S2, S2>(cubit2, _id2);
      combined = _scope.combine2<S1, S2, D>(field1, field2, widget.select);
      _cubit1 = cubit1;
      _cubit2 = cubit2;
      _select = widget.select;
      _field1 = field1;
      _field2 = field2;
      _combined = combined;
    }
    return ValueListenableBuilder<D>(
      valueListenable: combined,
      builder: (context, data, _) {
        ConnectObserver.instance?.onBuild(widget.debugLabel);
        return widget.builder(context, data, cubit1, cubit2);
      },
    );
  }
}

/// Argument-keyed variant of [Connect]: selects a value from one Cubit's state
/// using [arg], so one widget can watch a single entry of a keyed state (for
/// example one item of a `Map`) and rebuild only when that entry changes.
///
/// [select] must be a static or top-level function (not a closure), because
/// the selector is what identifies the projection. [select] runs with the
/// current [arg]; the builder runs again only when the selected value changes
/// by `!=`. A change of [arg] or of [select] recomputes the value at once.
///
/// The Cubit is resolved on every build, from [resolve] or from
/// `context.read<C>()`. When the resolved Cubit changes, the old subscription
/// is cancelled and the new Cubit is subscribed.
///
/// [debugLabel] is reported to [ConnectObserver] on each builder run.
class ConnectFor<C extends StateStreamable<S>, S, A, D> extends StatefulWidget {
  const ConnectFor({
    required this.arg,
    required this.select,
    required this.builder,
    this.resolve,
    this.debugLabel,
    super.key,
  });

  final A arg;
  final D Function(S state, A arg) select;
  final Widget Function(BuildContext context, D data, C cubit) builder;
  final C Function(BuildContext context)? resolve;
  final String? debugLabel;

  @override
  State<ConnectFor<C, S, A, D>> createState() =>
      _ConnectForState<C, S, A, D>();
}

class _ConnectForState<C extends StateStreamable<S>, S, A, D>
    extends State<ConnectFor<C, S, A, D>> {
  C? _cubit;
  StreamSubscription<S>? _subscription;
  late D _data;

  @override
  void didUpdateWidget(ConnectFor<C, S, A, D> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cubit = _cubit;
    if (cubit != null &&
        (widget.arg != oldWidget.arg || widget.select != oldWidget.select)) {
      _data = widget.select(cubit.state, widget.arg);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  void _onState(S state) {
    final next = widget.select(state, widget.arg);
    if (next != _data) {
      setState(() => _data = next);
    }
  }

  /// Moves the subscription to [cubit] and recomputes the value from it.
  void _attach(C cubit) {
    _subscription?.cancel();
    _cubit = cubit;
    _data = widget.select(cubit.state, widget.arg);
    _subscription = cubit.stream.listen(_onState);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = widget.resolve?.call(context) ?? context.read<C>();
    if (!identical(cubit, _cubit)) _attach(cubit);
    ConnectObserver.instance?.onBuild(widget.debugLabel);
    return widget.builder(context, _data, cubit);
  }
}
