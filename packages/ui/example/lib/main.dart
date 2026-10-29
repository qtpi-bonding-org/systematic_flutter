import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';

final _demoPalette = AppColorPalette(
  colors: {
    'color1': const Color(0xFF0B152C),
    'color2': const Color(0xFFE8EFFF),
    'color3': const Color(0xFF00C3FF),
    'interactable': const Color(0xFF00C3FF),
    'error': const Color(0xFF3D1616),
  },
  name: 'qtpi_ui Demo',
);

void main() {
  final theme = ThemeService(lightPalette: _demoPalette);
  final controller = StorybookThemeController(theme);
  runApp(StorybookApp(
    controller: controller,
    themeBuilder: (c) => ThemeData(
      brightness: c.isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.tokens['color3'] ?? const Color(0xFF00C3FF),
        brightness: c.isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: c.tokens['color1'],
    ),
    stories: qtpiStories(controller.tokens),
  ));
}
