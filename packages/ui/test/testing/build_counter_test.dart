import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_ui/testing.dart';

void main() {
  setUp(BuildCounter.reset);

  testWidgets('counts increment on rebuild', (tester) async {
    final n = ValueNotifier(0);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ValueListenableBuilder<int>(
        valueListenable: n,
        builder: (_, v, __) =>
            BuildCounter(id: 'a', child: Text('$v')),
      ),
    ));
    expect(BuildCounter.count('a'), 1);
    n.value = 1;
    await tester.pump();
    expect(BuildCounter.count('a'), 2);
  });

  testWidgets('counts are per id', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: [
        BuildCounter(id: 'a', child: Text('x')),
        BuildCounter(id: 'b', child: Text('y')),
      ]),
    ));
    expect(BuildCounter.count('a'), 1);
    expect(BuildCounter.count('b'), 1);
    expect(BuildCounter.count('c'), 0);
  });

  testWidgets('reset clears counts', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: BuildCounter(id: 'a', child: Text('x')),
    ));
    BuildCounter.reset();
    expect(BuildCounter.count('a'), 0);
  });
}
