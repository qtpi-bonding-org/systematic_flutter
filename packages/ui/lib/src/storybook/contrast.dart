import 'dart:math' as math;
import 'package:flutter/material.dart';

double _linearize(double c) {
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color c) {
  return 0.2126 * _linearize(c.r) +
      0.7152 * _linearize(c.g) +
      0.0722 * _linearize(c.b);
}

/// WCAG 2.x contrast ratio between two colors (1.0 .. 21.0).
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// WCAG pass level for normal/large body text.
String contrastRating(double ratio) {
  if (ratio >= 7.0) return 'AAA';
  if (ratio >= 4.5) return 'AA';
  if (ratio >= 3.0) return 'AA Large';
  return 'Fail';
}
