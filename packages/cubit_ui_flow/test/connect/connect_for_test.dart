import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MapCubit extends Cubit<Map<String, String>> {
  MapCubit() : super(const {'a': 'A', 'b': 'B'});
  void set(String id, String v) => emit({...state, id: v});
}

String titleOf(Map<String, String> s, String id) => s[id] ?? '';

void main() {
  testWidgets('selects per arg and does not rebuild when another item changes',
      (t) async {
    final cubit = MapCubit();
    final builds = <String, int>{'a': 0, 'b': 0};
    Widget tile(String id) => ConnectFor<MapCubit, Map<String, String>, String, String>(
          arg: id,
          select: titleOf,
          builder: (c, d, cu) {
            builds[id] = builds[id]! + 1;
            return Text('$id=$d', textDirection: TextDirection.ltr);
          },
        );
    await t.pumpWidget(BlocProvider.value(
      value: cubit,
      child: Column(children: [tile('a'), tile('b')]),
    ));
    expect(find.text('a=A'), findsOneWidget);
    expect(find.text('b=B'), findsOneWidget);
    cubit.set('a', 'A2');
    await t.pump();
    await t.pump();
    expect(find.text('a=A2'), findsOneWidget);
    expect(builds['a'], 2);
    expect(builds['b'], 1);
  });

  testWidgets('passes the cubit to the builder and honours resolve', (t) async {
    final cubit = MapCubit();
    MapCubit? got;
    await t.pumpWidget(
      ConnectFor<MapCubit, Map<String, String>, String, String>(
        arg: 'a',
        select: titleOf,
        resolve: (_) => cubit,
        builder: (c, d, cu) {
          got = cu;
          return Text(d, textDirection: TextDirection.ltr);
        },
      ),
    );
    expect(got, same(cubit));
  });

  testWidgets('arg change recomputes and rebuilds', (t) async {
    final cubit = MapCubit();
    Widget build(String id) => BlocProvider.value(
          value: cubit,
          child: ConnectFor<MapCubit, Map<String, String>, String, String>(
            arg: id,
            select: titleOf,
            builder: (c, d, cu) => Text('$id=$d', textDirection: TextDirection.ltr),
          ),
        );
    await t.pumpWidget(build('a'));
    expect(find.text('a=A'), findsOneWidget);
    await t.pumpWidget(build('b'));
    expect(find.text('b=B'), findsOneWidget);
    cubit.set('b', 'B2');
    await t.pump();
    await t.pump();
    expect(find.text('b=B2'), findsOneWidget);
  });

  testWidgets('disposal cancels the subscription', (t) async {
    final cubit = MapCubit();
    var builds = 0;
    await t.pumpWidget(BlocProvider.value(
      value: cubit,
      child: ConnectFor<MapCubit, Map<String, String>, String, String>(
        arg: 'a',
        select: titleOf,
        builder: (c, d, cu) {
          builds++;
          return Text(d, textDirection: TextDirection.ltr);
        },
      ),
    ));
    await t.pumpWidget(const SizedBox());
    cubit.set('a', 'zzz');
    await t.pump();
    await t.pump();
    expect(builds, 1);
    expect(t.takeException(), isNull);
  });
}
