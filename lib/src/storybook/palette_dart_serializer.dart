// lib/src/storybook/palette_dart_serializer.dart
import 'package:flutter/material.dart';

/// Serializes a live palette back into the exact Dart source both apps use:
///
/// ```dart
/// AppColorPalette(
///   colors: {
///     'color1': const Color(0xFF0B152C),
///   },
///   name: 'Episutra Bioluminescent',
/// )
/// ```
///
/// Note: hand-written `// comments` in the source palette files cannot be
/// reproduced — round-trip output is comment-less (spec §4.4).
String paletteToDart(Map<String, Color> colors, {required String name}) {
  final buf = StringBuffer()
    ..writeln('AppColorPalette(')
    ..writeln('  colors: {');
  colors.forEach((key, color) {
    // ignore: deprecated_member_use — .value is the stable ARGB int on the SDK floor
    final hex = color.value.toRadixString(16).toUpperCase().padLeft(8, '0');
    buf.writeln("    '$key': const Color(0x$hex),");
  });
  buf
    ..writeln('  },')
    ..writeln("  name: '$name',")
    ..write(')');
  return buf.toString();
}