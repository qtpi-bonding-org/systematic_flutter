import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

enum TestRoute { home, login }

String _nameOf(TestRoute route) => route.name;

TestRoute? _routeFrom(String name) {
  for (final route in TestRoute.values) {
    if (route.name == name) return route;
  }
  return null;
}

GoRouter _buildRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (_, __) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reports the current route and navigates', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    final target = GoRouterTarget<TestRoute>(
      router: router,
      routeName: _nameOf,
      routeFromName: _routeFrom,
    );

    expect(target.current, TestRoute.home);

    target.go(TestRoute.login);
    await tester.pumpAndSettle();

    expect(target.current, TestRoute.login);
  });

  test('current is null before the router resolves a match', () {
    final target = GoRouterTarget<TestRoute>(
      router: _buildRouter(),
      routeName: _nameOf,
      routeFromName: _routeFrom,
    );

    expect(target.current, isNull);
  });
}
