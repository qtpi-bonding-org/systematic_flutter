import 'package:flutter/material.dart';

/// Utilities for calculating luminance-based color transformations.
class LuminanceCalculator {
  /// Inverts the luminance of a color while preserving hue and saturation.
  /// 
  /// Dark colors become light, light colors become dark.
  /// Pure mathematical inversion with no clamping.
  static Color invertLuminance(Color color) {
    final hsl = HSLColor.fromColor(color);
    
    // Pure mathematical luminance inversion
    final newLightness = 1.0 - hsl.lightness;
    
    return hsl.withLightness(newLightness).toColor();
  }
  
  /// Adjusts the lightness of a color by a specific amount.
  /// 
  /// [amount] - Positive values make lighter, negative values make darker
  /// [amount] should be between -1.0 and 1.0
  /// Result is clamped to valid range [0.0, 1.0]
  static Color adjustLightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }
  
  /// Creates a darker variant of the given color.
  static Color darken(Color color, [double amount = 0.2]) {
    return adjustLightness(color, -amount);
  }
  
  /// Creates a lighter variant of the given color.
  static Color lighten(Color color, [double amount = 0.2]) {
    return adjustLightness(color, amount);
  }
  
  /// Calculates the contrast ratio between two colors.
  /// 
  /// Returns a value between 1.0 (no contrast) and 21.0 (maximum contrast).
  /// WCAG AA requires a minimum of 4.5:1 for normal text.
  static double contrastRatio(Color color1, Color color2) {
    final luminance1 = color1.computeLuminance();
    final luminance2 = color2.computeLuminance();
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Checks if two colors have sufficient contrast for accessibility.
  /// 
  /// [level] - 'AA' for 4.5:1 ratio, 'AAA' for 7:1 ratio
  static bool hasGoodContrast(Color foreground, Color background, {String level = 'AA'}) {
    final ratio = contrastRatio(foreground, background);
    return level == 'AAA' ? ratio >= 7.0 : ratio >= 4.5;
  }
}