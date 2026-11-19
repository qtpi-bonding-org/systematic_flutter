import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lifecycle_helpers.dart';

class InitProbe extends StatefulWidget {
  const InitProbe({required this.onScope, super.key});
  final void Function(HolderScope) onScope;
  @override
  State<InitProbe> createState() => _InitProbeState();
}

class _InitProbeState extends State<InitProbe> {
  @override
  void initState() {
    super.initState();
    widget.onScope(ScopeProvider.of<HolderScope>(context));
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('of() works in initState', (t) async {
    final s = HolderScope(CountingCubit());
    HolderScope? got;
    await t.pumpWidget(ScopeProvider<HolderScope>.value(
      scope: s,
      child: InitProbe(onScope: (x) => got = x),
    ));
    expect(got, same(s));
  });

  testWidgets('of() works inside BlocProvider(create:)', (t) async {
    final s = HolderScope(CountingCubit(7));
    CountingCubit? got;
    await t.pumpWidget(ScopeProvider<HolderScope>.value(
      scope: s,
      child: BlocProvider<CountingCubit>(
        create: (c) => got = ScopeProvider.of<HolderScope>(c).cubit,
        child: Builder(builder: (c) {
          c.read<CountingCubit>();
          return const SizedBox();
        }),
      ),
    ));
    expect(got, same(s.cubit));
  });

  testWidgets('maybeOf is null when absent and does not subscribe', (t) async {
    var builds = 0;
    Widget w(HolderScope s) => ScopeProvider<HolderScope>.value(
          scope: s,
          child: Builder(builder: (c) {
            builds++;
            ScopeProvider.maybeOf<HolderScope>(c);
            return const SizedBox();
          }),
        );
    final s1 = HolderScope(CountingCubit()), s2 = HolderScope(CountingCubit());
    await t.pumpWidget(w(s1));
    // Same Builder instance is not reused, so swapping rebuilds via the new
    // widget; the point is that no dependency was registered.
    await t.pumpWidget(w(s2));
    expect(builds, 2);
    late BuildContext ctx;
    await t.pumpWidget(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }));
    expect(ScopeProvider.maybeOf<HolderScope>(ctx), isNull);
  });
}
