import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';

void main() {
  group('DsRow', () {
    testWidgets('middle slot is expanded', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DsRow(middle: const Text('mid'))),
      ));
      expect(find.byType(Expanded), findsOneWidget);
    });

    testWidgets('no middle renders Spacer', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DsRow(
          start: const Text('s'),
          end: const Text('e'),
        )),
      ));
      expect(find.byType(Spacer), findsOneWidget);
    });

    testWidgets('renders start and end alongside middle', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DsRow(
          start: const Text('s'),
          middle: const Text('mid'),
          end: const Text('e'),
        )),
      ));
      expect(find.text('s'), findsOneWidget);
      expect(find.text('mid'), findsOneWidget);
      expect(find.text('e'), findsOneWidget);
    });
  });
}
