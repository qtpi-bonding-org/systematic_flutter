import 'package:flutter/material.dart';

/// Pure color palette interface with no UI semantics.
/// 
/// Defines colors by enumeration (color1, color2, etc.) without
/// any assumptions about how they will be used in the UI.
abstract class IColorPalette {
  /// All colors in the palette as a map.
  /// Keys are color identifiers (e.g., 'color1', 'color2', 'neutral1', etc.)
  Map<String, Color> get colors;
  
  /// Gets a color by its identifier.
  Color? getColor(String identifier);
  
  /// Gets all color identifiers in the palette.
  List<String> get colorIdentifiers;
  
  /// Mathematical symmetry for automatic theme generation.
  /// 
  /// Returns a palette where each color is luminance-inverted.
  /// Dark colors become light, light colors become dark.
  IColorPalette get symmetricPalette;
  
  /// Optional theme metadata for sharing and identification
  String? get name;
  String? get description;
  List<String>? get tags;
}