import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

enum TestRoute { boot, home, login }

class RecordingTarget implements IRouteTarget<TestRoute> {
  RecordingTarget([this._current = TestRoute.boot]);

  TestRoute? _current;
  final List<TestRoute> navigations = <TestRoute>[];

  bool lagging = false;

  @override
  TestRoute? get current => _current;

  @override
  void go(TestRoute route) {
    navigations.add(route);
    if (!lagging) _current = route;
  }

  /// Simulates navigation by something other than the binding.
  void setCurrent(TestRoute? route) => _current = route;
}

class GatePolicy extends NavigationPolicy<TestRoute> {
  GatePolicy({required this.signedIn, required this.detail});

  final SnapshotPart<bool> signedIn;
  final SnapshotPart<bool> detail;
  /// Every applied decision, with whether the router was actually moved.
  final List<({TestRoute route, bool navigated})> applied =
      <({TestRoute route, bool navigated})>[];
  int decideCalls = 0;

  @override
  List<SnapshotPart<Object?>> get parts => [signedIn, detail];

  @override
  RouteDecision<TestRoute> decide() {
    decideCalls++;
    final auth = signedIn.read();
    if (auth is! PartReady<bool>) return const RouteWait<TestRoute>();
    if (!auth.value) return const RouteGo<TestRoute>(TestRoute.login);
    final extra = detail.read();
    if (extra is! PartReady<bool>) return const RouteWait<TestRoute>();
    return const RouteGo<TestRoute>(TestRoute.home);
  }

  @override
  void onDecisionApplied(TestRoute route, {required bool navigated}) =>
      applied.add((route: route, navigated: navigated));
}

class StayPolicy extends NavigationPolicy<TestRoute> {
  @override
  List<SnapshotPart<Object?>> get parts => const [];

  @override
  RouteDecision<TestRoute> decide() => const RouteStay<TestRoute>();
}

/// Invalidates a part it also reads — the pattern that overflowed the stack
/// in revision 1 and livelocked on microtasks in revision 2.
///
/// [invalidateBudget] bounds the damage so a regression fails the suite
/// instead of wedging the isolate: a microtask livelock starves timers, so
/// neither the test timeout nor any frame would ever fire.
class SelfInvalidatingPolicy extends NavigationPolicy<TestRoute> {
  SelfInvalidatingPolicy(this.part, {this.invalidateBudget = 5000});

  final SnapshotPart<bool> part;
  final int invalidateBudget;
  int decideCalls = 0;

  @override
  List<SnapshotPart<Object?>> get parts => [part];

  @override
  RouteDecision<TestRoute> decide() {
    decideCalls++;
    part.read();
    if (decideCalls <= invalidateBudget) part.invalidate();
    return const RouteGo<TestRoute>(TestRoute.home);
  }
}

void main() {
  test('wait does not navigate', () {
    final target = RecordingTarget();
    NavigationBinding<TestRoute>(
      policy: GatePolicy(
        signedIn: SnapshotPart<bool>.loading('auth'),
        detail: SnapshotPart<bool>.loading('detail'),
      ),
      target: target,
    ).start();

    expect(target.navigations, isEmpty);
  });

  test('stay never navigates', () {
    final target = RecordingTarget();
    final binding =
        NavigationBinding<TestRoute>(policy: StayPolicy(), target: target)
          ..start();

    expect(target.navigations, isEmpty);
    expect(binding.lastDecision, const RouteStay<TestRoute>());
  });

  test('go navigates once and reports it applied once', () {
    final target = RecordingTarget();
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: SnapshotPart<bool>.loading('detail'),
    );
    final binding =
        NavigationBinding<TestRoute>(policy: policy, target: target)..start();

    binding.evaluate();
    binding.evaluate();

    // Navigation happens once; the hook fires on every applied decision, and
    // only the first reports navigated: true.
    expect(target.navigations, [TestRoute.login]);
    expect(policy.applied.length, 3);
    expect(policy.applied.every((e) => e.route == TestRoute.login), isTrue);
    expect(policy.applied.map((e) => e.navigated), [true, false, false]);
  });

  test('re-commands a lagging target rather than remembering the destination',
      () {
    final target = RecordingTarget()..lagging = true;
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: SnapshotPart<bool>.loading('detail'),
    );
    final binding =
        NavigationBinding<TestRoute>(policy: policy, target: target)..start();

    binding.evaluate();

    // Matches boot_routing_decider.dart:320-332, which compares against the
    // live route only. Remembering the last commanded route would suppress
    // the duplicate here, but would also suppress a legitimate re-assert
    // forever once the user navigates to a route outside TRoute (where the
    // target reports null). A harmless duplicate beats a permanent lockout.
    expect(target.navigations, [TestRoute.login, TestRoute.login]);
  });

  test('re-asserts a route the user navigated away from', () {
    final target = RecordingTarget();
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: SnapshotPart<bool>.loading('detail'),
    );
    final binding =
        NavigationBinding<TestRoute>(policy: policy, target: target)..start();

    expect(target.navigations, [TestRoute.login]);

    // The user navigates somewhere the policy has no enum value for, which is
    // how GoRouterTarget reports every non-policy route.
    target.setCurrent(null);
    binding.evaluate();

    expect(target.navigations, [TestRoute.login, TestRoute.login],
        reason: 'the gate must keep working after user-driven navigation');
  });

  test('a decision for the route already showing applies without navigating',
      () {
    final target = RecordingTarget(TestRoute.login);
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: SnapshotPart<bool>.loading('detail'),
    );
    NavigationBinding<TestRoute>(policy: policy, target: target).start();

    expect(target.navigations, isEmpty);
    // The hook still fires. boot_routing_decider.dart writes
    // _confirmedLatchKey (line 291) and _lastDeployProgressRoute (line 311)
    // on exactly this path, where no navigation occurs; only
    // _hasLeftBootScreen (line 330) is gated on having actually moved.
    expect(policy.applied.single.route, TestRoute.login);
    expect(policy.applied.single.navigated, isFalse);
  });

  test('re-evaluates when a read part settles', () async {
    final target = RecordingTarget();
    NavigationBinding<TestRoute>(
      policy: GatePolicy(
        signedIn: SnapshotPart<bool>(name: 'auth', load: () async => false),
        detail: SnapshotPart<bool>.loading('detail'),
      ),
      target: target,
    ).start();

    expect(target.navigations, isEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(target.navigations, [TestRoute.login]);
  });

  test('does not subscribe to an unread part', () {
    final detail = SnapshotPart<bool>.ready('detail', true);
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: detail,
    );
    NavigationBinding<TestRoute>(policy: policy, target: RecordingTarget())
        .start();

    final before = policy.decideCalls;
    detail.invalidate();

    expect(policy.decideCalls, before);
  });

  test('the first evaluation subscribes only after decide returns', () {
    final policy = SelfInvalidatingPolicy(
      SnapshotPart<bool>(name: 'p', load: () => true),
    );
    NavigationBinding<TestRoute>(policy: policy, target: RecordingTarget())
        .start();

    expect(policy.decideCalls, 1,
        reason: 'pins the flaw in the original version of the test below: '
            '_resubscribe runs after decide() returns, so an invalidate during '
            'the first decide() notifies nobody and proves nothing');
  });

  test('a bounded burst of invalidations settles instead of spinning',
      () async {
    // Invalidates three times, then stops -- the shape of a policy that
    // clears a cache on a state change and then converges.
    final policy = SelfInvalidatingPolicy(
      SnapshotPart<bool>(name: 'p', load: () => true),
      invalidateBudget: 3,
    );
    final binding = NavigationBinding<TestRoute>(
      policy: policy,
      target: RecordingTarget(),
    )..start();

    // The second evaluation is the dangerous one: the part is subscribed by
    // now, so invalidate() inside decide() reaches _onPartChanged.
    binding.evaluate();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(policy.decideCalls, lessThan(25),
        reason: 'reruns must settle, not chain microtask after microtask');
  });

  test('the rerun budget resets once a chain settles', () async {
    final policy = SelfInvalidatingPolicy(
      SnapshotPart<bool>(name: 'p', load: () => true),
      invalidateBudget: 3,
    );
    final binding = NavigationBinding<TestRoute>(
      policy: policy,
      target: RecordingTarget(),
    )..start();

    // Two separate bursts must not accumulate toward the cap.
    binding.evaluate();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final afterFirst = policy.decideCalls;

    policy.part.invalidate();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(policy.decideCalls, greaterThan(afterFirst));
    expect(policy.decideCalls, lessThan(25));
  });

  test('an unsettleable policy throws rather than hanging', () async {
    final errors = <Object>[];
    final policy = SelfInvalidatingPolicy(
      SnapshotPart<bool>(name: 'p', load: () => true),
    );

    await runZonedGuarded(() async {
      NavigationBinding<TestRoute>(
        policy: policy,
        target: RecordingTarget(),
      )
        ..start()
        ..evaluate();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }, (error, _) => errors.add(error));

    expect(errors, isNotEmpty,
        reason: 'a genuine cycle must fail loudly, not silently wedge the app');
    expect(errors.first, isA<StateError>());
  });

  test('a part that stops being read is unsubscribed', () async {
    // One binding, one policy, gate flipped between evaluations. The first
    // pass reads `detail`; after the flip decide() returns before reaching
    // it, and that subscription must be dropped rather than carried over.
    var signedIn = true;
    final authChanges = StreamController<void>.broadcast();
    addTearDown(authChanges.close);

    final auth = SnapshotPart<bool>.observed(
      name: 'auth',
      read: () => signedIn,
      changes: authChanges.stream,
    );
    final detail = SnapshotPart<bool>.ready('detail', true);
    final policy = GatePolicy(signedIn: auth, detail: detail);
    NavigationBinding<TestRoute>(policy: policy, target: RecordingTarget())
        .start();

    // Confirm detail really is a dependency while the gate is open.
    final openCalls = policy.decideCalls;
    detail.invalidate();
    expect(policy.decideCalls, greaterThan(openCalls),
        reason: 'precondition: detail is subscribed while the gate is open');

    // Close the gate; decide() now returns before reading detail.
    signedIn = false;
    authChanges.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final closedCalls = policy.decideCalls;
    detail.invalidate();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(policy.decideCalls, closedCalls,
        reason: 'the dependency set must be recomputed, not accumulated');
  });

  test('reads after an await inside decide are not tracked', () async {
    // Documents why decide() must be synchronous: ambient tracking is
    // restored when the synchronous body returns, so a deferred read
    // registers no dependency and the binding never re-evaluates for it.
    final deferred = SnapshotPart<bool>.ready('deferred', true);
    final policy = _DeferredReadPolicy(deferred);
    final binding = NavigationBinding<TestRoute>(
      policy: policy,
      target: RecordingTarget(),
    )..start();

    await Future<void>.delayed(const Duration(milliseconds: 10));
    final before = policy.decideCalls;

    deferred.invalidate();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(policy.decideCalls, before,
        reason: 'the deferred read never became a dependency');
    expect(binding.lastDecision, isA<RouteGo<TestRoute>>());
  });

  test('dispose stops re-evaluation', () async {
    final target = RecordingTarget();
    final binding = NavigationBinding<TestRoute>(
      policy: GatePolicy(
        signedIn: SnapshotPart<bool>(name: 'auth', load: () async => false),
        detail: SnapshotPart<bool>.loading('detail'),
      ),
      target: target,
    )..start();

    binding.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(target.navigations, isEmpty);
  });
}

/// Reads a part from inside a `.then()`, i.e. after the synchronous body of
/// decide() has already returned.
class _DeferredReadPolicy extends NavigationPolicy<TestRoute> {
  _DeferredReadPolicy(this.part);

  final SnapshotPart<bool> part;
  int decideCalls = 0;

  @override
  List<SnapshotPart<Object?>> get parts => [part];

  @override
  RouteDecision<TestRoute> decide() {
    decideCalls++;
    Future<void>.delayed(Duration.zero).then((_) => part.read());
    return const RouteGo<TestRoute>(TestRoute.home);
  }
}
