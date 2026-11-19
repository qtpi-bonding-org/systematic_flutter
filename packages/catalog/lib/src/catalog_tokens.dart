import 'package:flutter/material.dart';

/// Live theme inputs the catalog page lets a developer tweak.
@immutable
class CatalogTokens {
  const CatalogTokens({
    this.seed = Colors.indigo,
    this.fontFamily,
    this.fontScale = 1.0,
    this.spacingScale = 1.0,
  });

  final Color seed;
  final String? fontFamily;
  final double fontScale;
  final double spacingScale;

  CatalogTokens copyWith({
    Color? seed,
    String? fontFamily,
    double? fontScale,
    double? spacingScale,
  }) {
    return CatalogTokens(
      seed: seed ?? this.seed,
      fontFamily: fontFamily ?? this.fontFamily,
      fontScale: fontScale ?? this.fontScale,
      spacingScale: spacingScale ?? this.spacingScale,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CatalogTokens &&
      other.seed == seed &&
      other.fontFamily == fontFamily &&
      other.fontScale == fontScale &&
      other.spacingScale == spacingScale;

  @override
  int get hashCode => Object.hash(seed, fontFamily, fontScale, spacingScale);
}
