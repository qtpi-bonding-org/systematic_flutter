import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

enum TestRoute { home, login, gone }

class TestPolicy extends NavigationPolicy<TestRoute> {
  TestPolicy({required this.signedIn, required this.exists});

  final SnapshotPart<bool> signedIn;
  final SnapshotPart<bool> exists;
  final List<TestRoute> navigated = <TestRoute>[];

  @override
  List<SnapshotPart<Object?>> get parts => [signedIn, exists];

  @override
  RouteDecision<TestRoute> decide() {
    final auth = signedIn.read();
    if (auth is! PartReady<bool>) return const RouteWait<TestRoute>();
    if (auth.value) return const RouteGo<TestRoute>(TestRoute.home);

    final existence = exists.read();
    if (existence is! PartReady<bool>) return const RouteWait<TestRoute>();
    return existence.value
        ? const RouteGo<TestRoute>(TestRoute.login)
        : const RouteGo<TestRoute>(TestRoute.gone);
  }

  @override
  void onNavigated(TestRoute route) => navigated.add(route);
}

void main() {
  test('table-driven decisions over seeded parts', () {
    final rows = <({
      String name,
      bool? auth,
      bool? exists,
      RouteDecision<TestRoute> expected
    })>[
      (name: 'auth unresolved', auth: null, exists: null, expected: const RouteWait<TestRoute>()),
      (name: 'signed in', auth: true, exists: null, expected: const RouteGo<TestRoute>(TestRoute.home)),
      (name: 'signed out, exists', auth: false, exists: true, expected: const RouteGo<TestRoute>(TestRoute.login)),
      (name: 'signed out, gone', auth: false, exists: false, expected: const RouteGo<TestRoute>(TestRoute.gone)),
      (name: 'signed out, existence unresolved', auth: false, exists: null, expected: const RouteWait<TestRoute>()),
    ];

    for (final row in rows) {
      final auth = row.auth;
      final exists = row.exists;
      final policy = TestPolicy(
        signedIn: auth == null
            ? SnapshotPart<bool>.loading('auth')
            : SnapshotPart<bool>.ready('auth', auth),
        exists: exists == null
            ? SnapshotPart<bool>.loading('exists')
            : SnapshotPart<bool>.ready('exists', exists),
      );

      expect(policy.decide(), row.expected, reason: row.name);
    }
  });

  test('a part the policy never reaches is never read', () {
    final exists = SnapshotPart<bool>.ready('exists', true);
    final policy = TestPolicy(
      signedIn: SnapshotPart<bool>.ready('auth', true),
      exists: exists,
    );

    final context = EvaluationContext();
    EvaluationContext.track(context, policy.decide);

    expect(context.reads, isNot(contains(exists)));
  });

  test('repeating an evaluation yields the same decision', () {
    final policy = TestPolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      exists: SnapshotPart<bool>.ready('exists', false),
    );

    expect(policy.decide(), policy.decide());
  });

  test('onNavigated defaults to doing nothing', () {
    final policy = _MinimalPolicy();
    expect(() => policy.onNavigated(TestRoute.home), returnsNormally);
  });
}

class _MinimalPolicy extends NavigationPolicy<TestRoute> {
  @override
  List<SnapshotPart<Object?>> get parts => const [];

  @override
  RouteDecision<TestRoute> decide() => const RouteStay<TestRoute>();
}
