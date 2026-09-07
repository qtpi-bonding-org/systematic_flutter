import 'route_decision.dart';
import 'snapshot_part.dart';

/// The one interface a consuming app implements.
abstract class NavigationPolicy<TRoute> {
  /// Every part this policy may read.
  List<SnapshotPart<Object?>> get parts;

  /// Decides where the user belongs, given the parts read.
  ///
  /// MUST be synchronous.
  RouteDecision<TRoute> decide();

  /// Called after the binding actually navigated to [route].
  void onNavigated(TRoute route) {}
}
