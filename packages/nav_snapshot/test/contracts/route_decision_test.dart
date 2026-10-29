import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

enum TestRoute { home, login }

void main() {
  test('stay and wait are distinct decisions', () {
    expect(const RouteStay<TestRoute>(), isNot(const RouteWait<TestRoute>()));
  });

  test('go carries its destination', () {
    expect(const RouteGo<TestRoute>(TestRoute.login).to, TestRoute.login);
  });

  test('a switch over the union is exhaustive without a default', () {
    String describe(RouteDecision<TestRoute> decision) => switch (decision) {
          RouteStay<TestRoute>() => 'stay',
          RouteWait<TestRoute>() => 'wait',
          RouteGo<TestRoute>(to: final route) => 'go:${route.name}',
        };

    expect(describe(const RouteStay<TestRoute>()), 'stay');
    expect(describe(const RouteWait<TestRoute>()), 'wait');
    expect(describe(const RouteGo<TestRoute>(TestRoute.home)), 'go:home');
  });

  test('equal decisions compare equal', () {
    expect(const RouteGo<TestRoute>(TestRoute.home),
        const RouteGo<TestRoute>(TestRoute.home));
    expect(const RouteGo<TestRoute>(TestRoute.home),
        isNot(const RouteGo<TestRoute>(TestRoute.login)));
    expect(const RouteStay<TestRoute>(), const RouteStay<TestRoute>());
  });
}
