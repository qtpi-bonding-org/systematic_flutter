// lib/src/storybook/widgets/palette_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'theme_controller_import.dart';

/// One editable row per palette token: a tappable swatch (opens an HSL
/// color picker dialog) + a hex text field for direct hex entry.
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

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (_) => _ColorPickerDialog(initial: widget.color, name: widget.name),
    );
    if (picked != null) widget.onHex(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Tooltip(
            message: 'Click to open color picker',
            child: GestureDetector(
              onTap: () => _openPicker(context),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.color,
                  border: Border.all(color: Colors.black26),
                  shape: BoxShape.circle,
                ),
              ),
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

// ─── Color picker dialog ──────────────────────────────────────────────────────

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial, required this.name});

  final Color initial;
  final String name;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _h; // 0–360
  late double _s; // 0–1
  late double _l; // 0–1

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initial);
    _h = hsl.hue;
    _s = hsl.saturation;
    _l = hsl.lightness;
  }

  Color get _color => HSLColor.fromAHSL(1, _h, _s, _l).toColor();

  // Guard: only take hue from the wheel when the color isn't achromatic —
  // grey/black/white have no meaningful hue and would reset it to 0 (red).
  void _onWheelChange(Color c) {
    final hsl = HSLColor.fromColor(c);
    setState(() {
      if (hsl.saturation > 0.001 && hsl.lightness > 0.001 && hsl.lightness < 0.999) {
        _h = hsl.hue;
      }
      _s = hsl.saturation;
      _l = hsl.lightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.name),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HueRingPicker(
              pickerColor: _color,
              onColorChanged: _onWheelChange,
              enableAlpha: false,
              displayThumbColor: true,
            ),
            const SizedBox(height: 8),
            _buildSlider('H', _h, 0, 360, (v) => setState(() => _h = v)),
            _buildSlider('S', _s * 100, 0, 100, (v) => setState(() => _s = v / 100)),
            _buildSlider('L', _l * 100, 0, 100, (v) => setState(() => _l = v / 100)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(
          width: 36,
          child: Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 11), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
