import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';

void main() {
  group('DsGroup', () {
    testWidgets('non-tappable renders plain Padding', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DsGroup(
          testId: 'test-group',
          child: const Text('content'),
        )),
      ));
      expect(find.byType(InkWell), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('tappable renders InkWell and fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DsGroup(
          testId: 'tap-group',
          onTap: () => tapped = true,
          child: const Text('tap me'),
        )),
      ));
      expect(find.byType(InkWell), findsOneWidget);
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('showChevron renders chevron_right icon when tappable', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DsGroup(
          testId: 'chevron-group',
          onTap: () {},
          showChevron: true,
          child: const Text('nav'),
        )),
      ));
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('showChevron is false by default', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: DsGroup(
          testId: 'no-chevron',
          onTap: () {},
          child: const Text('tap'),
        )),
      ));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });
}
