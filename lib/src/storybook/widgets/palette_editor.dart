// lib/src/storybook/widgets/palette_editor.dart
import 'package:flutter/material.dart';
import 'theme_controller_import.dart';

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

class _TokenRow extends StatefulWidget {
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

  static String _toHex(Color c) {
    return c.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0');
  }

  @override
  State<_TokenRow> createState() => _TokenRowState();
}

class _TokenRowState extends State<_TokenRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _TokenRow._toHex(widget.color));
  }

  @override
  void didUpdateWidget(covariant _TokenRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) {
      _ctrl.text = _TokenRow._toHex(widget.color);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.color,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.name)),
          SizedBox(
            width: 110,
            child: TextField(
              key: ValueKey('hex_${widget.name}'),
              controller: _ctrl,
              decoration: const InputDecoration(prefixText: '0x', isDense: true),
              onSubmitted: (raw) {
                final parsed = _TokenRow._parseHex(raw);
                if (parsed != null) widget.onHex(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
