// lib/src/storybook/widgets/palette_editor.dart
import 'package:flutter/material.dart';
import '../theme_controller.dart';

/// One editable row per palette token: a swatch + a hex field. Plain Flutter.
/// Entering a valid 6- (RRGGBB) or 8-digit (AARRGGBB) hex applies a live
/// override via [ThemeController.setToken].
class PaletteEditor extends StatelessWidget {
  const PaletteEditor({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final tokens = controller.tokens;
        return ListView(
          shrinkWrap: true,
          children: [
            for (final entry in tokens.entries)
              _TokenRow(
                name: entry.key,
                color: entry.value,
                onHex: (color) => controller.setToken(entry.key, color),
              ),
          ],
        );
      },
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.name, required this.color, required this.onHex});

  final String name;
  final Color color;
  final ValueChanged<Color> onHex;

  static Color? _parseHex(String raw) {
    var hex = raw.trim().replaceAll('#', '').toUpperCase();
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final initial = color.value.toRadixString(16).toUpperCase().padLeft(8, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          SizedBox(
            width: 110,
            child: TextField(
              key: ValueKey('hex_$name'),
              controller: TextEditingController(text: initial),
              decoration: const InputDecoration(prefixText: '0x', isDense: true),
              onSubmitted: (raw) {
                final parsed = _parseHex(raw);
                if (parsed != null) onHex(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
