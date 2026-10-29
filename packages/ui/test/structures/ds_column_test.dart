import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_ui/systematic_ui.dart';

void main() {
  group('DsColumn', () {
    testWidgets('renders single child without spacing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DsColumn(children: [const Text('only')])),
      ));
      expect(find.text('only'), findsOneWidget);
      expect(find.byType(VSpace), findsNothing);
    });

    testWidgets('interleaves VSpace.x1 between children by default',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DsColumn(children: [
          const Text('a'),
          const Text('b'),
          const Text('c'),
        ])),
      ));
      expect(find.byType(VSpace), findsNWidgets(2));
    });

    testWidgets('uses custom spacing widget when provided', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DsColumn(
          spacing: VSpace.x3,
          children: [const Text('a'), const Text('b')],
        )),
      ));
      final spacer = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(spacer.height, AppSizes.space * 3);
    });

    testWidgets('respects mainAxisSize parameter', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DsColumn(
          mainAxisSize: MainAxisSize.min,
          children: [const Text('a')],
        )),
      ));
      final col = tester.widget<Column>(find.byType(Column).first);
      expect(col.mainAxisSize, MainAxisSize.min);
    });
  });
}
