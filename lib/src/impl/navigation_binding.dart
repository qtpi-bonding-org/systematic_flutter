import 'dart:async';

import '../contracts/navigation_policy.dart';
import '../contracts/route_decision.dart';
import '../contracts/route_target.dart';
import '../contracts/snapshot_part.dart';
import 'evaluation_context.dart';

/// Runs a [NavigationPolicy] and applies its decisions to an [IRouteTarget].
class NavigationBinding<TRoute> {
  /// Creates a binding over [policy] and [target].
  NavigationBinding({
    required NavigationPolicy<TRoute> policy,
    required IRouteTarget<TRoute> target,
  })  : _policy = policy,
        _target = target;

  final NavigationPolicy<TRoute> _policy;
  final IRouteTarget<TRoute> _target;
  final Set<SnapshotPart<Object?>> _subscribed = <SnapshotPart<Object?>>{};

  RouteDecision<TRoute>? _lastDecision;
  TRoute? _lastCommanded;
  bool _disposed = false;
  bool _evaluating = false;
  bool _rerunScheduled = false;
  int _chainedReruns = 0;

  /// How many reruns may chain before the binding declares the policy
  /// unsettleable.
  ///
  /// A rerun is scheduled on a microtask, and Dart drains microtasks before
  /// timers — so an endless chain starves timers and frames, and neither a
  /// test timeout nor the UI would ever recover. Failing loudly beats
  /// wedging the isolate, which for a boot router is a frozen splash screen.
  static const int maxChainedReruns = 20;

  /// The most recent decision, or null before the first evaluation.
  RouteDecision<TRoute>? get lastDecision => _lastDecision;

  /// Runs the first evaluation and begins reacting to part changes.
  void start() => evaluate();

  /// Runs the policy, updates subscriptions, and applies the decision.
  RouteDecision<TRoute> evaluate() {
    if (_disposed) return _lastDecision ?? RouteWait<TRoute>();
    if (_evaluating) {
      _scheduleRerun();
      return _lastDecision ?? RouteWait<TRoute>();
    }

    _evaluating = true;
    try {
      final context = EvaluationContext();
      final decision = EvaluationContext.track(context, _policy.decide);
      _resubscribe(context.reads);
      _lastDecision = decision;
      _apply(decision);
      return decision;
    } finally {
      _evaluating = false;
    }
  }

  /// Stops reacting to part changes.
  void dispose() {
    _disposed = true;
    for (final part in _subscribed) {
      part.removeListener(_onPartChanged);
    }
    _subscribed.clear();
  }

  void _scheduleRerun() {
    if (_rerunScheduled) return;

    _chainedReruns++;
    if (_chainedReruns > maxChainedReruns) {
      final names = _subscribed.map((part) => part.name).join(', ');
      _chainedReruns = 0;
      throw StateError(
        'NavigationBinding re-evaluated $maxChainedReruns times without '
        'settling. A policy that invalidates a part it also reads cannot '
        'converge. Subscribed parts: $names',
      );
    }

    _rerunScheduled = true;
    scheduleMicrotask(() {
      _rerunScheduled = false;
      if (_disposed) return;
      evaluate();
      // Nothing asked for another pass, so the chain settled.
      if (!_rerunScheduled) _chainedReruns = 0;
    });
  }

  void _resubscribe(Set<Object> reads) {
    final next = reads.whereType<SnapshotPart<Object?>>().toSet();

    for (final part in _subscribed.difference(next)) {
      part.removeListener(_onPartChanged);
    }
    for (final part in next.difference(_subscribed)) {
      part.addListener(_onPartChanged);
    }

    _subscribed
      ..clear()
      ..addAll(next);
  }

  void _apply(RouteDecision<TRoute> decision) {
    if (decision is! RouteGo<TRoute>) return;
    final destination = decision.to;
    if (_lastCommanded == destination) return;
    if (_target.current == destination) return;

    _lastCommanded = destination;
    _target.go(destination);
    _policy.onNavigated(destination);
  }

  void _onPartChanged() {
    if (_disposed) return;
    if (_evaluating) {
      _scheduleRerun();
      return;
    }
    evaluate();
  }
}
