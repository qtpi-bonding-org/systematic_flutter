import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Live theme inputs the catalog page lets a developer tweak.
///
/// The catalog only edits these values; the app's `themeBuilder` decides what
/// they mean by mapping them onto its real design tokens.
@immutable
class CatalogTokens {
  const CatalogTokens({
    this.seed = Colors.indigo,
    this.fontFamily,
    this.fontScale = 1.0,
    this.spacingScale = 1.0,
    this.sizeScale = 1.0,
    this.colorOverrides = const {},
  });

  final Color seed;
  final String? fontFamily;
  final double fontScale;
  final double spacingScale;
  final double sizeScale;

  /// Palette key -> colour chosen in the side panel.
  final Map<String, Color> colorOverrides;

  CatalogTokens copyWith({
    Color? seed,
    String? fontFamily,
    double? fontScale,
    double? spacingScale,
    double? sizeScale,
    Map<String, Color>? colorOverrides,
  }) {
    return CatalogTokens(
      seed: seed ?? this.seed,
      fontFamily: fontFamily ?? this.fontFamily,
      fontScale: fontScale ?? this.fontScale,
      spacingScale: spacingScale ?? this.spacingScale,
      sizeScale: sizeScale ?? this.sizeScale,
      colorOverrides: colorOverrides ?? this.colorOverrides,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CatalogTokens &&
      other.seed == seed &&
      other.fontFamily == fontFamily &&
      other.fontScale == fontScale &&
      other.spacingScale == spacingScale &&
      other.sizeScale == sizeScale &&
      mapEquals(other.colorOverrides, colorOverrides);

  @override
  int get hashCode => Object.hash(
        seed,
        fontFamily,
        fontScale,
        spacingScale,
        sizeScale,
        Object.hashAllUnordered([
          for (final e in colorOverrides.entries) Object.hash(e.key, e.value),
        ]),
      );
}
