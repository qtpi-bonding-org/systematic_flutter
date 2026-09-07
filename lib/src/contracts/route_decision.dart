/// What a policy concluded about where the user should be.
sealed class RouteDecision<TRoute> {
  /// Creates a decision.
  const RouteDecision();
}

/// Decided: leave the user where they are.
final class RouteStay<TRoute> extends RouteDecision<TRoute> {
  /// Creates a stay decision.
  const RouteStay();

  @override
  bool operator ==(Object other) => other is RouteStay<TRoute>;

  @override
  int get hashCode => (RouteStay<TRoute>).hashCode;
}

/// Undecided: one or more inputs have not resolved.
final class RouteWait<TRoute> extends RouteDecision<TRoute> {
  /// Creates a wait decision.
  const RouteWait();

  @override
  bool operator ==(Object other) => other is RouteWait<TRoute>;

  @override
  int get hashCode => (RouteWait<TRoute>).hashCode;
}

/// Decided: the user belongs at [to].
final class RouteGo<TRoute> extends RouteDecision<TRoute> {
  /// Creates a go decision targeting [to].
  const RouteGo(this.to);

  /// The destination.
  final TRoute to;

  @override
  bool operator ==(Object other) => other is RouteGo<TRoute> && other.to == to;

  @override
  int get hashCode => Object.hash(RouteGo<TRoute>, to);
}
