import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';

ThemeService _svc() => ThemeService(
      lightPalette: AppColorPalette(
        colors: {'color1': const Color(0xFF0B152C)},
        name: 'Test',
      ),
    );

void main() {
  group('StorybookThemeController', () {
    test('tokens reflect the service palette', () {
      final c = StorybookThemeController(_svc());
      expect(c.tokens['color1'], const Color(0xFF0B152C));
    });

    test('setToken overrides a color and notifies', () {
      final c = StorybookThemeController(_svc());
      var notified = false;
      c.addListener(() => notified = true);
      c.setToken('color1', const Color(0xFFABCDEF));
      expect(c.tokens['color1'], const Color(0xFFABCDEF));
      expect(notified, isTrue);
    });

    test('reset clears overrides', () {
      final c = StorybookThemeController(_svc());
      c.setToken('color1', const Color(0xFFABCDEF));
      c.reset();
      expect(c.tokens['color1'], const Color(0xFF0B152C));
    });

    test('isDark setter drives the service', () {
      final c = StorybookThemeController(_svc());
      c.isDark = true;
      expect(c.isDark, isTrue);
    });

    test('devicePreset stores and notifies', () {
      final c = StorybookThemeController(_svc());
      var notified = false;
      c.addListener(() => notified = true);
      c.devicePreset = DevicePreset.ipad;
      expect(c.devicePreset, DevicePreset.ipad);
      expect(notified, isTrue);
    });
  });
}
