import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';

void main() {
  group('UiScaler', () {
    test('returns unscaled value before init', () {
      expect(UiScaler.instance.px(100), 100.0);
      expect(UiScaler.instance.sp(16), 16.0);
    });

    testWidgets('clamps scale factor between 0.85 and 1.15', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            UiScaler.instance.init(context);
            return child!;
          },
          home: Builder(builder: (context) {
            final factor = UiScaler.instance.scaleFactor;
            expect(factor, greaterThanOrEqualTo(0.85));
            expect(factor, lessThanOrEqualTo(1.15));
            return const SizedBox();
          }),
        ),
      );
    });

    test('px returns 0 for 0 input', () {
      expect(UiScaler.instance.px(0), 0.0);
    });
  });
}
