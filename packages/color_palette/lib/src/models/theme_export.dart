import 'package:flutter/material.dart';
import '../interfaces/color_palette.dart';

/// Represents a theme that can be exported and shared.
class ThemeExport {
  final String name;
  final String description;
  final String author;
  final List<String> tags;
  final DateTime created;
  final String version;
  
  /// The light mode palette
  final Map<String, String> lightColors;
  
  /// Optional dark mode palette (if null, will be auto-generated)
  final Map<String, String>? darkColors;
  
  const ThemeExport({
    required this.name,
    required this.description,
    required this.author,
    required this.tags,
    required this.created,
    required this.lightColors,
    this.darkColors,
    this.version = '1.0',
  });
  
  /// Creates a ThemeExport from a color palette.
  factory ThemeExport.fromPalette({
    required IColorPalette palette,
    required String name,
    required String description,
    required String author,
    List<String> tags = const [],
    IColorPalette? darkPalette,
  }) {
    return ThemeExport(
      name: name,
      description: description,
      author: author,
      tags: tags,
      created: DateTime.now(),
      lightColors: _paletteToColorMap(palette),
      darkColors: darkPalette != null ? _paletteToColorMap(darkPalette) : null,
    );
  }
  
  /// Converts the export to JSON for sharing.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'author': author,
      'tags': tags,
      'created': created.toIso8601String(),
      'version': version,
      'lightColors': lightColors,
      if (darkColors != null) 'darkColors': darkColors,
    };
  }
  
  /// Creates a ThemeExport from JSON.
  factory ThemeExport.fromJson(Map<String, dynamic> json) {
    return ThemeExport(
      name: json['name'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      tags: List<String>.from(json['tags'] as List),
      created: DateTime.parse(json['created'] as String),
      version: json['version'] as String? ?? '1.0',
      lightColors: Map<String, String>.from(json['lightColors'] as Map),
      darkColors: json['darkColors'] != null 
          ? Map<String, String>.from(json['darkColors'] as Map)
          : null,
    );
  }
  
  /// Converts a color palette to a string map for serialization.
  static Map<String, String> _paletteToColorMap(IColorPalette palette) {
    final colorMap = <String, String>{};
    
    for (final entry in palette.colors.entries) {
      final identifier = entry.key;
      final color = entry.value;
      colorMap[identifier] = '#${color.value.toRadixString(16).padLeft(8, '0')}';
    }
    
    return colorMap;
  }
  
  /// Converts a color map back to individual colors.
  static Color _colorFromHex(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16));
  }
}