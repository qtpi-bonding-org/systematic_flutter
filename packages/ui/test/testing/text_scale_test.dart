import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_ui/systematic_ui.dart';
import 'package:systematic_ui/testing.dart';

void main() {
  testWidgets('passes for a layout that holds at every scale', (tester) async {
    await expectNoErrorsAtTextScales(
      tester,
      (_) => const MaterialApp(
        home: Scaffold(body: Center(child: Text('Hello'))),
      ),
    );
  });

  testWidgets('fails when a fixed-width row overflows at large text', (
    tester,
  ) async {
    final failure = await _failureOf(
      () => expectNoErrorsAtTextScales(
        tester,
        (_) => const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80,
              child: Row(children: [Text('A long label that needs room')]),
            ),
          ),
        ),
      ),
    );
    expect(failure, contains('text scale'));
  });

  testWidgets('iconTheme scales icons with the system text size', (
    tester,
  ) async {
    Widget app(double scale) => MaterialApp(
          theme:
              ThemeData(iconTheme: const SystematicSizes.standard().iconTheme),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Center(child: Icon(Icons.close)),
        );

    await tester.pumpWidget(app(1.0));
    final normal = tester.getSize(find.byType(Icon)).width;
    await tester.pumpWidget(app(2.0));
    final large = tester.getSize(find.byType(Icon)).width;
    expect(large, greaterThan(normal));
  });
}

Future<String> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } on TestFailure catch (e) {
    return e.message ?? '';
  }
  fail('expected the check to fail');
}
