import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';

AppColorPalette _palette(String name, Color fill) => AppColorPalette(
  colors: {'color1': fill, 'accent': const Color(0xFF00C3FF)},
  name: name,
);

void main() {
  group('ThemeService', () {
    test('returns lightPalette when not dark mode', () {
      final light = _palette('light', const Color(0xFFFFFFFF));
      final svc = ThemeService(lightPalette: light);
      expect(svc.currentPalette.name, 'light');
    });

    test('returns lightPalette when darkPalette is null and dark mode toggled', () {
      final light = _palette('light', const Color(0xFFFFFFFF));
      final svc = ThemeService(lightPalette: light)..toggleDarkMode();
      expect(svc.currentPalette.name, 'light');
    });

    test('returns darkPalette when dark mode set and darkPalette provided', () {
      final light = _palette('light', const Color(0xFFFFFFFF));
      final dark = _palette('dark', const Color(0xFF000000));
      final svc = ThemeService(lightPalette: light, darkPalette: dark)..setDarkMode(true);
      expect(svc.currentPalette.name, 'dark');
    });

    test('notifies listeners on toggleDarkMode', () {
      final svc = ThemeService(lightPalette: _palette('p', Colors.white));
      var notified = false;
      svc.addListener(() => notified = true);
      svc.toggleDarkMode();
      expect(notified, isTrue);
    });

    test('setDarkMode does not notify when value unchanged', () {
      final svc = ThemeService(lightPalette: _palette('p', Colors.white));
      var count = 0;
      svc.addListener(() => count++);
      svc.setDarkMode(false); // already false
      expect(count, 0);
    });

    test('setOverride merges into current palette', () {
      const overrideKey = 'color1';
      const newColor = Color(0xFFABCDEF);
      final svc = ThemeService(lightPalette: _palette('p', Colors.white));
      svc.setOverride(overrideKey, newColor);
      expect(svc.currentPalette.getColor(overrideKey), newColor);
    });

    test('setOverride notifies listeners', () {
      final svc = ThemeService(lightPalette: _palette('p', Colors.white));
      var notified = false;
      svc.addListener(() => notified = true);
      svc.setOverride('color1', Colors.red);
      expect(notified, isTrue);
    });

    test('clearOverrides restores base palette color', () {
      const original = Color(0xFFFFFFFF);
      final svc = ThemeService(lightPalette: _palette('p', original));
      svc.setOverride('color1', Colors.red);
      svc.clearOverrides();
      expect(svc.currentPalette.getColor('color1'), original);
    });

    test('overrides getter returns current override map', () {
      final svc = ThemeService(lightPalette: _palette('p', Colors.white));
      svc.setOverride('accent', Colors.blue);
      expect(svc.overrides['accent'], Colors.blue);
    });
  });
}
