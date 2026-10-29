import 'route_decision.dart';
import 'snapshot_part.dart';

/// The one interface a consuming app implements.
abstract class NavigationPolicy<TRoute> {
  /// Every part this policy may read.
  ///
  /// Used for lifecycle only. Which parts are actually read is discovered per
  /// evaluation, so a part listed here but never reached is never loaded.
  List<SnapshotPart<Object?>> get parts;

  /// Decides where the user belongs, given the parts read.
  ///
  /// MUST be synchronous. Dependency tracking is ambient and does not survive
  /// an `await`, so an async implementation would silently record only the
  /// reads before its first suspension.
  ///
  /// May read app-owned fields on the policy itself; those fields must be
  /// constructor-settable so tests can seed them.
  RouteDecision<TRoute> decide();

  /// Called after the binding applied a [RouteGo] for [route].
  ///
  /// [navigated] is true only when the router was actually told to move; it
  /// is false when the decision resolved to the route already showing.
  ///
  /// This is where cross-evaluation memory belongs. Writing such state inside
  /// [decide] would set it on evaluations that concluded nothing, and the
  /// distinction matters because real policies need both kinds: a latch
  /// recording "we have confirmed this session" is written whenever the
  /// decision was reached, while "we have left the boot screen" is written
  /// only when the user actually moved.
  void onDecisionApplied(TRoute route, {required bool navigated}) {}
}
