import 'package:go_router/go_router.dart';

import '../contracts/route_target.dart';

/// Applies route decisions to a [GoRouter].
class GoRouterTarget<TRoute> implements IRouteTarget<TRoute> {
  /// Creates a target over [router].
  GoRouterTarget({
    required GoRouter router,
    required String Function(TRoute route) routeName,
    required TRoute? Function(String name) routeFromName,
  })  : _router = router,
        _routeName = routeName,
        _routeFromName = routeFromName;

  final GoRouter _router;
  final String Function(TRoute route) _routeName;
  final TRoute? Function(String name) _routeFromName;

  @override
  TRoute? get current {
    final name = _currentName();
    if (name == null) return null;
    return _routeFromName(name);
  }

  @override
  void go(TRoute route) => _router.goNamed(_routeName(route));

  /// `GoRouter.state` throws on an empty match list before the first frame
  /// resolves, which is exactly when a boot policy runs.
  String? _currentName() {
    try {
      return _router.state.name;
    } on StateError {
      return null;
    }
  }
}
