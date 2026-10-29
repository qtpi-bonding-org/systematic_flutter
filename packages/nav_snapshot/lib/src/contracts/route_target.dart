/// Where a decision is applied. Implemented by a router adapter.
abstract interface class IRouteTarget<TRoute> {
  /// The route currently shown, or null when it cannot be determined.
  TRoute? get current;

  /// Navigates to [route].
  void go(TRoute route);
}
