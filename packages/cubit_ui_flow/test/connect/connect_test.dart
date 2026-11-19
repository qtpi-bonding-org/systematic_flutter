import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class Two {
  const Two(this.a, this.b);
  final int a, b;
}

class TwoCubit extends Cubit<Two> {
  TwoCubit() : super(const Two(0, 0));
}

class IntCubit extends Cubit<int> {
  IntCubit([super.initial = 0]);
}

int selectA(Two s) => s.a;
bool selectEven(int s) => s.isEven;
int sumAB(Two s, int b) => s.a + b;
bool bothEven(Two s, int b) => s.a.isEven && b.isEven;

class ResolveAdapter extends CubitAdapter<IntCubit, int> {
  const ResolveAdapter(this.other, {super.key});
  final IntCubit other;
  @override
  IntCubit resolveCubit(BuildContext context) => other;
  @override
  Widget buildAdapter(BuildContext context, CubitAdapterState<IntCubit, int> a) {
    return Text('v${a.cubit.state}', textDirection: TextDirection.ltr);
  }
}

class PlainAdapter extends CubitAdapter<IntCubit, int> {
  const PlainAdapter({super.key});
  @override
  Widget buildAdapter(BuildContext context, CubitAdapterState<IntCubit, int> a) {
    return Text('v${a.cubit.state}', textDirection: TextDirection.ltr);
  }
}

void main() {
  testWidgets('Connect builds with selected data and rebuilds only on change', (t) async {
    final cubit = TwoCubit();
    var builds = 0;
    await t.pumpWidget(BlocProvider.value(
      value: cubit,
      child: Connect<TwoCubit, Two, int>(
        select: selectA,
        builder: (c, d, cu) {
          builds++;
          return Text('a$d', textDirection: TextDirection.ltr);
        },
      ),
    ));
    expect(find.text('a0'), findsOneWidget);
    expect(builds, 1);
    cubit.emit(const Two(0, 5));
    await t.pump(); await t.pump(); // stream delivery is a microtask
    expect(builds, 1);
    cubit.emit(const Two(3, 5));
    await t.pump(); await t.pump(); // stream delivery is a microtask
    expect(find.text('a3'), findsOneWidget);
    expect(builds, 2);
  });

  testWidgets('Connect resolve reads a cubit not on the tree', (t) async {
    final cubit = IntCubit(4);
    IntCubit? got;
    await t.pumpWidget(Connect<IntCubit, int, bool>(
      select: selectEven,
      resolve: (_) => cubit,
      builder: (c, d, cu) {
        got = cu;
        return Text('$d', textDirection: TextDirection.ltr);
      },
    ));
    expect(find.text('true'), findsOneWidget);
    expect(got, same(cubit));
    cubit.emit(5);
    await t.pump(); await t.pump(); // stream delivery is a microtask
    expect(find.text('false'), findsOneWidget);
  });

  testWidgets('Connect2 rebuilds only when combined data changes', (t) async {
    final c1 = TwoCubit();
    final c2 = IntCubit();
    var builds = 0;
    await t.pumpWidget(Connect2<TwoCubit, Two, IntCubit, int, bool>(
      select: bothEven,
      resolve1: (_) => c1,
      resolve2: (_) => c2,
      builder: (c, d, a, b) {
        builds++;
        return Text('$d', textDirection: TextDirection.ltr);
      },
    ));
    expect(builds, 1);
    c1.emit(const Two(2, 9)); // still both even
    await t.pump(); await t.pump(); // stream delivery is a microtask
    expect(builds, 1);
    c2.emit(1);
    await t.pump(); await t.pump(); // stream delivery is a microtask
    expect(find.text('false'), findsOneWidget);
    expect(builds, 2);
    c2.emit(4);
    await t.pump(); await t.pump(); // stream delivery is a microtask
    expect(find.text('true'), findsOneWidget);
    expect(builds, 3);
  });

  testWidgets('Connect2 reads from tree by default', (t) async {
    final c1 = TwoCubit();
    final c2 = IntCubit(3);
    await t.pumpWidget(MultiBlocProvider(
      providers: [BlocProvider.value(value: c1), BlocProvider.value(value: c2)],
      child: Connect2<TwoCubit, Two, IntCubit, int, int>(
        select: sumAB,
        builder: (c, d, a, b) => Text('s$d', textDirection: TextDirection.ltr),
      ),
    ));
    expect(find.text('s3'), findsOneWidget);
    c1.emit(const Two(4, 0));
    await t.pump(); await t.pump(); // stream delivery is a microtask
    expect(find.text('s7'), findsOneWidget);
  });

  testWidgets('CubitAdapter resolveCubit override is used', (t) async {
    final other = IntCubit(7);
    await t.pumpWidget(ResolveAdapter(other));
    expect(find.text('v7'), findsOneWidget);
  });

  testWidgets('CubitAdapter default resolves via context.read', (t) async {
    await t.pumpWidget(BlocProvider.value(value: IntCubit(2), child: const PlainAdapter()));
    expect(find.text('v2'), findsOneWidget);
  });
}
