import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lifecycle_helpers.dart';

Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump();
}

Widget txt(String s) => Text(s, textDirection: TextDirection.ltr);

void main() {
  group('Connect', () {
    Widget app(HolderScope s, int Function(int) select, void Function() onBuild) =>
        ScopeProvider<HolderScope>.value(
          scope: s,
          child: Connect<CountingCubit, int, int>(
            select: select,
            resolve: (c) => ScopeProvider.of<HolderScope>(c).cubit,
            builder: (c, d, cu) {
              onBuild();
              return txt('d$d');
            },
          ),
        );

    testWidgets('select change rebuilds with new selection, old field released',
        (t) async {
      final cubit = CountingCubit(3);
      var builds = 0;
      await t.pumpWidget(app(HolderScope(cubit), ident, () => builds++));
      expect(find.text('d3'), findsOneWidget);
      expect(cubit.listeners, 1);
      await t.pumpWidget(app(HolderScope(cubit), doubled, () => builds++));
      await settle(t);
      expect(find.text('d6'), findsOneWidget);
      expect(cubit.listeners, 1);
      cubit.emit(4);
      await settle(t);
      expect(find.text('d8'), findsOneWidget);
    });

    testWidgets('resolve returning a different cubit switches to it', (t) async {
      final a = CountingCubit(1), b = CountingCubit(10);
      var builds = 0;
      await t.pumpWidget(app(HolderScope(a), ident, () => builds++));
      expect(find.text('d1'), findsOneWidget);
      await t.pumpWidget(app(HolderScope(b), ident, () => builds++));
      await settle(t);
      expect(find.text('d10'), findsOneWidget);
      expect(a.listeners, 0);
      expect(b.listeners, 1);
      final before = builds;
      a.emit(99);
      await settle(t);
      expect(builds, before);
      expect(find.text('d10'), findsOneWidget);
      b.emit(11);
      await settle(t);
      expect(find.text('d11'), findsOneWidget);
    });

    testWidgets('without resolve, a swapped provider value is picked up',
        (t) async {
      final a = CountingCubit(1), b = CountingCubit(10);
      Widget w(CountingCubit c) => BlocProvider.value(
            value: c,
            child: Connect<CountingCubit, int, int>(
              select: ident,
              builder: (c, d, cu) => txt('d$d'),
            ),
          );
      await t.pumpWidget(w(a));
      await t.pumpWidget(w(b));
      await settle(t);
      expect(find.text('d10'), findsOneWidget);
      expect(a.listeners, 0); // BlocProvider adds its own listener to b
      b.emit(11);
      await settle(t);
      expect(find.text('d11'), findsOneWidget);
    });

    testWidgets('dispose cancels everything', (t) async {
      final a = CountingCubit();
      await t.pumpWidget(app(HolderScope(a), ident, () {}));
      expect(a.listeners, 1);
      await t.pumpWidget(const SizedBox());
      expect(a.listeners, 0);
    });
  });

  group('Connect2', () {
    Widget app(HolderScope s1, HolderScope s2, int Function(int, int) select) =>
        Connect2<CountingCubit, int, CountingCubit, int, int>(
          select: select,
          resolve1: (_) => s1.cubit,
          resolve2: (_) => s2.cubit,
          builder: (c, d, a, b) => txt('d$d'),
        );

    testWidgets('select change takes effect, no leak', (t) async {
      final a = CountingCubit(2), b = CountingCubit(3);
      await t.pumpWidget(app(HolderScope(a), HolderScope(b), sumAB));
      expect(find.text('d5'), findsOneWidget);
      await t.pumpWidget(app(HolderScope(a), HolderScope(b), prodAB));
      await settle(t);
      expect(find.text('d6'), findsOneWidget);
      expect(a.listeners, 1);
      expect(b.listeners, 1);
      a.emit(4);
      await settle(t);
      expect(find.text('d12'), findsOneWidget);
    });

    testWidgets('resolve returning different cubits switches', (t) async {
      final a = CountingCubit(2), b = CountingCubit(3);
      final a2 = CountingCubit(20), b2 = CountingCubit(30);
      await t.pumpWidget(app(HolderScope(a), HolderScope(b), sumAB));
      await t.pumpWidget(app(HolderScope(a2), HolderScope(b), sumAB));
      await settle(t);
      expect(find.text('d23'), findsOneWidget);
      expect(a.listeners, 0);
      await t.pumpWidget(app(HolderScope(a2), HolderScope(b2), sumAB));
      await settle(t);
      expect(find.text('d50'), findsOneWidget);
      expect(b.listeners, 0);
      expect(a2.listeners, 1);
      expect(b2.listeners, 1);
      a.emit(7);
      b.emit(7);
      await settle(t);
      expect(find.text('d50'), findsOneWidget);
      b2.emit(31);
      await settle(t);
      expect(find.text('d51'), findsOneWidget);
    });

    testWidgets('dispose cancels everything', (t) async {
      final a = CountingCubit(), b = CountingCubit();
      await t.pumpWidget(app(HolderScope(a), HolderScope(b), sumAB));
      expect(a.listeners + b.listeners, 2);
      await t.pumpWidget(const SizedBox());
      expect(a.listeners + b.listeners, 0);
    });
  });

  group('ConnectFor', () {
    Widget app(HolderScope s, int arg, int Function(int, int) select) =>
        ConnectFor<CountingCubit, int, int, int>(
          arg: arg,
          select: select,
          resolve: (_) => s.cubit,
          builder: (c, d, cu) => txt('d$d'),
        );

    testWidgets('arg and select changes recompute without leaking', (t) async {
      final a = CountingCubit(5);
      await t.pumpWidget(app(HolderScope(a), 1, plusArg));
      expect(find.text('d6'), findsOneWidget);
      await t.pumpWidget(app(HolderScope(a), 2, plusArg));
      expect(find.text('d7'), findsOneWidget);
      await t.pumpWidget(app(HolderScope(a), 2, timesArg));
      expect(find.text('d10'), findsOneWidget);
      expect(a.listeners, 1);
      a.emit(6);
      await settle(t);
      expect(find.text('d12'), findsOneWidget);
    });

    testWidgets('resolve returning a different cubit switches to it', (t) async {
      final a = CountingCubit(1), b = CountingCubit(10);
      await t.pumpWidget(app(HolderScope(a), 0, plusArg));
      await t.pumpWidget(app(HolderScope(b), 0, plusArg));
      await settle(t);
      expect(find.text('d10'), findsOneWidget);
      expect(a.listeners, 0);
      expect(b.listeners, 1);
      a.emit(50);
      await settle(t);
      expect(find.text('d10'), findsOneWidget);
      b.emit(11);
      await settle(t);
      expect(find.text('d11'), findsOneWidget);
    });

    testWidgets('dispose cancels everything', (t) async {
      final a = CountingCubit();
      await t.pumpWidget(app(HolderScope(a), 0, plusArg));
      expect(a.listeners, 1);
      await t.pumpWidget(const SizedBox());
      expect(a.listeners, 0);
    });
  });
}
