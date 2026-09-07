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
}

class GatePolicy extends NavigationPolicy<TestRoute> {
  GatePolicy({required this.signedIn, required this.detail});

  final SnapshotPart<bool> signedIn;
  final SnapshotPart<bool> detail;
  final List<TestRoute> navigated = <TestRoute>[];
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
  void onNavigated(TestRoute route) => navigated.add(route);
}

class StayPolicy extends NavigationPolicy<TestRoute> {
  @override
  List<SnapshotPart<Object?>> get parts => const [];

  @override
  RouteDecision<TestRoute> decide() => const RouteStay<TestRoute>();
}

class SelfInvalidatingPolicy extends NavigationPolicy<TestRoute> {
  SelfInvalidatingPolicy(this.part);

  final SnapshotPart<bool> part;
  int decideCalls = 0;

  @override
  List<SnapshotPart<Object?>> get parts => [part];

  @override
  RouteDecision<TestRoute> decide() {
    decideCalls++;
    part.read();
    part.invalidate();
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

  test('go navigates once and fires onNavigated once', () {
    final target = RecordingTarget();
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: SnapshotPart<bool>.loading('detail'),
    );
    final binding =
        NavigationBinding<TestRoute>(policy: policy, target: target)..start();

    binding.evaluate();
    binding.evaluate();

    expect(target.navigations, [TestRoute.login]);
    expect(policy.navigated, [TestRoute.login]);
  });

  test('does not navigate twice when current lags behind go', () {
    final target = RecordingTarget()..lagging = true;
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: SnapshotPart<bool>.loading('detail'),
    );
    final binding =
        NavigationBinding<TestRoute>(policy: policy, target: target)..start();

    binding.evaluate();

    expect(target.navigations, [TestRoute.login]);
  });

  test('onNavigated does not fire when already at the destination', () {
    final target = RecordingTarget(TestRoute.login);
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: SnapshotPart<bool>.loading('detail'),
    );
    NavigationBinding<TestRoute>(policy: policy, target: target).start();

    expect(target.navigations, isEmpty);
    expect(policy.navigated, isEmpty);
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

  test('a policy that invalidates inside decide does not overflow', () async {
    final policy = SelfInvalidatingPolicy(
      SnapshotPart<bool>(name: 'p', load: () => true),
    );
    NavigationBinding<TestRoute>(policy: policy, target: RecordingTarget())
        .start();

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(policy.decideCalls, lessThan(50),
        reason: 'reruns must be coalesced, not recursed');
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
