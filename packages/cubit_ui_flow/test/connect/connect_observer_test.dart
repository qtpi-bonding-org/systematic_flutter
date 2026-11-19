import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lifecycle_helpers.dart';

class Recorder implements ConnectObserver {
  final labels = <String?>[];
  @override
  void onBuild(String? debugLabel) => labels.add(debugLabel);
}

Widget txt(String s) => Text(s, textDirection: TextDirection.ltr);

void main() {
  tearDown(() => ConnectObserver.instance = null);

  testWidgets('reports labels on builder runs only', (t) async {
    final rec = Recorder();
    ConnectObserver.instance = rec;
    final c = CountingCubit();
    await t.pumpWidget(BlocProvider.value(
      value: c,
      child: Column(textDirection: TextDirection.ltr, children: [
        Connect<CountingCubit, int, int>(
          debugLabel: 'one',
          select: ident,
          builder: (_, d, __) => txt('$d'),
        ),
        Connect2<CountingCubit, int, CountingCubit, int, int>(
          debugLabel: 'two',
          select: sumAB,
          resolve1: (_) => c,
          resolve2: (_) => c,
          builder: (_, d, __, ___) => txt('$d'),
        ),
        ConnectFor<CountingCubit, int, int, int>(
          debugLabel: 'for',
          arg: 1,
          select: plusArg,
          builder: (_, d, __) => txt('$d'),
        ),
      ]),
    ));
    expect(rec.labels.toSet(), {'one', 'two', 'for'});
    expect(rec.labels.length, 3);
    rec.labels.clear();
    c.emit(0); // no change: no builder run
    await t.pump();
    await t.pump();
    expect(rec.labels, isEmpty);
    c.emit(5);
    await t.pump();
    await t.pump();
    expect(rec.labels.where((l) => l == 'one').length, 1);
  });

  testWidgets('no-op without an observer', (t) async {
    expect(ConnectObserver.instance, isNull);
    await t.pumpWidget(BlocProvider.value(
      value: CountingCubit(),
      child: Connect<CountingCubit, int, int>(
        debugLabel: 'x',
        select: ident,
        builder: (_, d, __) => txt('$d'),
      ),
    ));
    expect(find.text('0'), findsOneWidget);
  });
}
