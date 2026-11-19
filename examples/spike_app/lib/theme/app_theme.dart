import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart'
    show AppColorPalette, IColorPalette;
import 'package:systematic_ui/systematic_ui.dart';

/// The app's colours. The symmetric palette (dark mode) inverts the neutrals.
final kPalette = AppColorPalette(colors: const {
  'color1': Color(0xFF3949AB),
  'color2': Color(0xFF00897B),
  'neutral1': Color(0xFF1B1B1F),
  'neutral2': Color(0xFF8A8A93),
  'neutral3': Color(0xFFF7F7FA),
});

class AppTheme {
  AppTheme._();

  static ThemeData build({
    required IColorPalette palette,
    required SystematicSizes sizes,
    required Brightness brightness,
    String? fontFamily,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.getColor('color1')!,
      brightness: brightness,
    ).copyWith(
      primary: palette.getColor('color1'),
      secondary: palette.getColor('color2'),
      surface: palette.getColor('neutral3'),
      onSurface: palette.getColor('neutral1'),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.getColor('neutral3'),
      fontFamily: fontFamily,
      extensions: [sizes],
      iconTheme: sizes.iconTheme,
    );
  }
}
