// test/storybook/palette_dart_serializer_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  group('paletteToDart', () {
    test('emits the AppColorPalette wrapper with 8-hex uppercase colors', () {
      final out = paletteToDart(
        {
          'color1': const Color(0xFF0B152C),
          'accent': const Color(0xFF00C3FF),
        },
        name: 'Episutra Bioluminescent',
      );
      expect(out, '''
AppColorPalette(
  colors: {
    'color1': const Color(0xFF0B152C),
    'accent': const Color(0xFF00C3FF),
  },
  name: 'Episutra Bioluminescent',
)''');
    });

    test('preserves non-FF alpha', () {
      final out = paletteToDart(
        {'ghost': const Color(0x0B00C3FF)},
        name: 'P',
      );
      expect(out.contains("'ghost': const Color(0x0B00C3FF),"), isTrue);
    });
  });
}