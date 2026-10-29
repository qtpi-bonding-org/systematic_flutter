import 'package:flutter/material.dart';
import 'luminance_calculator.dart';

/// Convenient extensions on Color for common operations.
extension ColorPaletteExtensions on Color {
  /// Returns the luminance-inverted version of this color.
  Color get inverted => LuminanceCalculator.invertLuminance(this);
  
  /// Returns a darker version of this color.
  Color darken([double amount = 0.2]) => LuminanceCalculator.darken(this, amount);
  
  /// Returns a lighter version of this color.
  Color lighten([double amount = 0.2]) => LuminanceCalculator.lighten(this, amount);
  
  /// Calculates contrast ratio with another color.
  double contrastWith(Color other) => LuminanceCalculator.contrastRatio(this, other);
  
  /// Checks if this color has good contrast with another color.
  bool hasGoodContrastWith(Color other, {String level = 'AA'}) {
    return LuminanceCalculator.hasGoodContrast(this, other, level: level);
  }
  
  /// Returns the HSL representation of this color.
  HSLColor get hsl => HSLColor.fromColor(this);
  
  /// Returns true if this is considered a "dark" color (lightness < 0.5).
  bool get isDark => hsl.lightness < 0.5;
  
  /// Returns true if this is considered a "light" color (lightness >= 0.5).
  bool get isLight => !isDark;
}