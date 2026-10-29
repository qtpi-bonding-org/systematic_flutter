import 'package:flutter/material.dart';
import '../interfaces/color_palette.dart';
import '../utils/luminance_calculator.dart';

/// Concrete implementation of IColorPalette with flexible color enumeration.
@immutable
class AppColorPalette implements IColorPalette {
  @override
  final Map<String, Color> colors;
  
  @override
  final String? name;
  @override
  final String? description;
  @override
  final List<String>? tags;
  
  /// Optional manual overrides for symmetric colors
  final Map<String, Color>? symmetricOverrides;
  
  AppColorPalette({
    required this.colors,
    this.name,
    this.description,
    this.tags,
    this.symmetricOverrides,
  });
  
  /// Creates a palette with enumerated colors (color1, color2, etc.)
  factory AppColorPalette.enumerated({
    required List<Color> colors,
    List<Color>? neutrals,
    String? name,
    String? description,
    List<String>? tags,
    Map<String, Color>? symmetricOverrides,
  }) {
    final colorMap = <String, Color>{};
    
    // Add enumerated colors
    for (int i = 0; i < colors.length; i++) {
      colorMap['color${i + 1}'] = colors[i];
    }
    
    // Add enumerated neutrals if provided
    if (neutrals != null) {
      for (int i = 0; i < neutrals.length; i++) {
        colorMap['neutral${i + 1}'] = neutrals[i];
      }
    }
    
    return AppColorPalette(
      colors: colorMap,
      name: name,
      description: description,
      tags: tags,
      symmetricOverrides: symmetricOverrides,
    );
  }
  
  /// Creates a basic palette with common defaults.
  factory AppColorPalette.basic({
    Color? color1,
    Color? color2,
    Color? color3,
    Color? color4,
    List<Color>? neutrals,
    String? name,
    String? description,
    List<String>? tags,
  }) {
    final colors = <Color>[
      color1 ?? const Color(0xFF1976D2),    // Blue
      color2 ?? const Color(0xFF388E3C),    // Green
      color3 ?? const Color(0xFFF57C00),    // Orange
      color4 ?? const Color(0xFFD32F2F),    // Red
    ];
    
    final defaultNeutrals = neutrals ?? [
      const Color(0xFF212121),    // Dark
      const Color(0xFF757575),    // Medium-dark
      const Color(0xFFBDBDBD),    // Medium-light
      const Color(0xFFFAFAFA),    // Light
    ];
    
    return AppColorPalette.enumerated(
      colors: colors,
      neutrals: defaultNeutrals,
      name: name,
      description: description,
      tags: tags,
    );
  }
  
  @override
  Color? getColor(String identifier) {
    return colors[identifier];
  }
  
  @override
  List<String> get colorIdentifiers => colors.keys.toList();
  
  @override
  IColorPalette get symmetricPalette {
    return AppColorPalette(
      colors: _generateSymmetricColors(),
      name: name != null ? '$name (Symmetric)' : null,
      description: description,
      tags: tags,
      symmetricOverrides: _reverseOverrides(),
    );
  }
  
  /// Generates symmetric colors using luminance inversion or manual overrides.
  Map<String, Color> _generateSymmetricColors() {
    final symmetricColors = <String, Color>{};
    
    for (final entry in colors.entries) {
      final identifier = entry.key;
      final color = entry.value;
      
      // Use manual override if provided, otherwise invert luminance
      if (symmetricOverrides?.containsKey(identifier) == true) {
        symmetricColors[identifier] = symmetricOverrides![identifier]!;
      } else {
        symmetricColors[identifier] = LuminanceCalculator.invertLuminance(color);
      }
    }
    
    return symmetricColors;
  }
  
  /// Creates reverse overrides for circular symmetry.
  Map<String, Color>? _reverseOverrides() {
    if (symmetricOverrides == null) return null;
    
    final reverseOverrides = <String, Color>{};
    for (final entry in symmetricOverrides!.entries) {
      final identifier = entry.key;
      final originalColor = colors[identifier];
      if (originalColor != null) {
        reverseOverrides[identifier] = originalColor;
      }
    }
    return reverseOverrides;
  }
  
  /// Creates a copy of this palette with some properties changed.
  AppColorPalette copyWith({
    Map<String, Color>? colors,
    String? name,
    String? description,
    List<String>? tags,
    Map<String, Color>? symmetricOverrides,
  }) {
    return AppColorPalette(
      colors: colors ?? this.colors,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      symmetricOverrides: symmetricOverrides ?? this.symmetricOverrides,
    );
  }
  
  /// Adds a new color to the palette.
  AppColorPalette addColor(String identifier, Color color) {
    final newColors = Map<String, Color>.from(colors);
    newColors[identifier] = color;
    return copyWith(colors: newColors);
  }
  
  /// Removes a color from the palette.
  AppColorPalette removeColor(String identifier) {
    final newColors = Map<String, Color>.from(colors);
    newColors.remove(identifier);
    return copyWith(colors: newColors);
  }
  
  /// Updates an existing color in the palette.
  AppColorPalette updateColor(String identifier, Color color) {
    if (!colors.containsKey(identifier)) {
      throw ArgumentError('Color identifier "$identifier" not found in palette');
    }
    return addColor(identifier, color);
  }
}