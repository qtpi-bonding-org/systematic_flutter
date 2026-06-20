import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  group('contrast', () {
    test('black on white is 21:1', () {
      final r = contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF));
      expect(r, closeTo(21.0, 0.01));
    });

    test('identical colors are 1:1', () {
      final r = contrastRatio(const Color(0xFF123456), const Color(0xFF123456));
      expect(r, closeTo(1.0, 0.001));
    });

    test('rating thresholds', () {
      expect(contrastRating(21.0), 'AAA');     // >= 7
      expect(contrastRating(5.0), 'AA');       // >= 4.5
      expect(contrastRating(3.5), 'AA Large'); // >= 3
      expect(contrastRating(2.0), 'Fail');     // < 3
    });
  });
}