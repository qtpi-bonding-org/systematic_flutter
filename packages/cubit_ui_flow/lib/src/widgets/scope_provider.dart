import 'package:flutter/widgets.dart';

import 'app_scope.dart';

/// Provides an [AppScope] to its subtree.
///
/// The default constructor creates the scope once, in [State.initState], and
/// disposes it when the widget is removed. [ScopeProvider.value] exposes a
/// scope the caller owns and never disposes it.
class ScopeProvider<T extends AppScope> extends StatefulWidget {
  const ScopeProvider({
    required this.create,
    required this.child,
    super.key,
  }) : scope = null;

  const ScopeProvider.value({
    required this.scope,
    required this.child,
    super.key,
  }) : create = null;

  /// Factory for an owned scope. Null for [ScopeProvider.value].
  final T Function()? create;

  /// The externally owned scope. Null for the default constructor.
  final T? scope;

  final Widget child;

  /// Returns the nearest [T] scope. Throws a [StateError] if none is provided.
  static T of<T extends AppScope>(BuildContext context) {
    final scope = maybeOf<T>(context);
    if (scope == null) {
      throw StateError(
        'No ScopeProvider<$T> found above this context. '
        'Wrap the subtree in ScopeProvider<$T>.',
      );
    }
    return scope;
  }

  /// Returns the nearest [T] scope, or null if none is provided.
  static T? maybeOf<T extends AppScope>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ScopeInherited<T>>()?.scope;

  @override
  State<ScopeProvider<T>> createState() => _ScopeProviderState<T>();
}

class _ScopeProviderState<T extends AppScope> extends State<ScopeProvider<T>> {
  T? _owned;

  @override
  void initState() {
    super.initState();
    final create = widget.create;
    if (create != null) _owned = create();
  }

  @override
  void dispose() {
    _owned?.dispose();
    _owned = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _owned ?? widget.scope!;
    return _ScopeInherited<T>(scope: scope, child: widget.child);
  }
}

class _ScopeInherited<T extends AppScope> extends InheritedWidget {
  const _ScopeInherited({required this.scope, required super.child});

  final T scope;

  @override
  bool updateShouldNotify(_ScopeInherited<T> oldWidget) =>
      !identical(oldWidget.scope, scope);
}
