// test/storybook/contrast_calculator_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  testWidgets('shows 21.00 and AAA for black vs white default selection',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContrastCalculator(tokens: {
          'black': const Color(0xFF000000),
          'white': const Color(0xFFFFFFFF),
        }),
      ),
    ));
    expect(find.textContaining('21.00'), findsOneWidget);
    expect(find.text('AAA'), findsOneWidget);
  });
}
