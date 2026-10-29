import 'package:flutter/material.dart';
import '../interfaces/color_palette.dart';

/// Utilities for calculating color contrast ratios and accessibility compliance.
class ContrastCalculator {
  /// Calculates the contrast ratio between two colors.
  /// 
  /// Returns a value between 1.0 (no contrast) and 21.0 (maximum contrast).
  /// WCAG AA requires a minimum of 4.5:1 for normal text.
  static double contrastRatio(Color foreground, Color background) {
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Checks if two colors meet WCAG accessibility standards.
  /// 
  /// [level] - 'AA' for 4.5:1 ratio, 'AAA' for 7:1 ratio
  /// [size] - 'normal' for regular text, 'large' for large text (lower requirements)
  static bool meetsWCAG(Color foreground, Color background, {String level = 'AA', String size = 'normal'}) {
    final ratio = contrastRatio(foreground, background);
    
    if (size == 'large') {
      // Large text has lower requirements
      return level == 'AAA' ? ratio >= 4.5 : ratio >= 3.0;
    } else {
      // Normal text requirements
      return level == 'AAA' ? ratio >= 7.0 : ratio >= 4.5;
    }
  }
  
  /// Gets accessibility grade for a color combination.
  /// 
  /// Returns 'AAA', 'AA', 'AA Large', or 'Fail'
  static String getAccessibilityGrade(Color foreground, Color background) {
    final ratio = contrastRatio(foreground, background);
    
    if (ratio >= 7.0) return 'AAA';
    if (ratio >= 4.5) return 'AA';
    if (ratio >= 3.0) return 'AA Large';
    return 'Fail';
  }
  
  /// Generates a contrast matrix for all color combinations in a palette.
  /// 
  /// Returns a map where keys are 'foreground_background' and values are contrast ratios.
  static Map<String, double> generateContrastMatrix(IColorPalette palette) {
    final matrix = <String, double>{};
    final colors = palette.colors;
    
    for (final foregroundEntry in colors.entries) {
      for (final backgroundEntry in colors.entries) {
        final key = '${foregroundEntry.key}_${backgroundEntry.key}';
        final ratio = contrastRatio(foregroundEntry.value, backgroundEntry.value);
        matrix[key] = ratio;
      }
    }
    
    return matrix;
  }
  
  /// Generates accessibility grades for all color combinations in a palette.
  static Map<String, String> generateAccessibilityMatrix(IColorPalette palette) {
    final matrix = <String, String>{};
    final colors = palette.colors;
    
    for (final foregroundEntry in colors.entries) {
      for (final backgroundEntry in colors.entries) {
        final key = '${foregroundEntry.key}_${backgroundEntry.key}';
        final grade = getAccessibilityGrade(foregroundEntry.value, backgroundEntry.value);
        matrix[key] = grade;
      }
    }
    
    return matrix;
  }
  
  /// Finds the best foreground color from a palette for a given background.
  static String? findBestForeground(IColorPalette palette, Color background) {
    String? bestColor;
    double bestRatio = 0.0;
    
    for (final entry in palette.colors.entries) {
      final ratio = contrastRatio(entry.value, background);
      if (ratio > bestRatio) {
        bestRatio = ratio;
        bestColor = entry.key;
      }
    }
    
    return bestColor;
  }
  
  /// Finds the best background color from a palette for a given foreground.
  static String? findBestBackground(IColorPalette palette, Color foreground) {
    String? bestColor;
    double bestRatio = 0.0;
    
    for (final entry in palette.colors.entries) {
      final ratio = contrastRatio(foreground, entry.value);
      if (ratio > bestRatio) {
        bestRatio = ratio;
        bestColor = entry.key;
      }
    }
    
    return bestColor;
  }
}