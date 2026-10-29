import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';

void main() {
  group('VSpace', () {
    testWidgets('x1 renders a SizedBox with height == AppSizes.space',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: VSpace.x1)));
      final box = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(box.height, AppSizes.space);
    });

    testWidgets('x2 is double x1', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: VSpace.x2)));
      final box = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(box.height, AppSizes.space * 2);
    });
  });

  group('HSpace', () {
    testWidgets('x1 renders a SizedBox with width == AppSizes.space',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: HSpace.x1)));
      final box = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(box.width, AppSizes.space);
    });
  });

  group('AppPadding', () {
    test('allSingle uses one space unit', () {
      expect(AppPadding.allSingle.left, AppSizes.space);
      expect(AppPadding.allSingle.top, AppSizes.space);
    });

    test('horizontalDouble uses 2x space', () {
      expect(AppPadding.horizontalDouble.left, AppSizes.space * 2);
      expect(AppPadding.horizontalDouble.top, 0.0);
    });
  });
}
