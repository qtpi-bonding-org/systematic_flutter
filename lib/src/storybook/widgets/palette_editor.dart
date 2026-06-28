// lib/src/storybook/widgets/palette_editor.dart
import 'package:flutter/material.dart';
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
  late HSLColor _hsl;
  late final TextEditingController _hexCtrl;

  @override
  void initState() {
    super.initState();
    _hsl = HSLColor.fromColor(widget.initial);
    _hexCtrl = TextEditingController(text: _toHex(_hsl.toColor()));
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  static String _toHex(Color c) {
    final rgb = c.toARGB32() & 0x00FFFFFF;
    return rgb.toRadixString(16).toUpperCase().padLeft(6, '0');
  }

  void _updateHsl(HSLColor hsl) {
    setState(() {
      _hsl = hsl;
      _hexCtrl.text = _toHex(hsl.toColor());
    });
  }

  void _applyHex(String raw) {
    final cleaned = raw.trim().replaceAll('#', '');
    if (cleaned.length == 6) {
      final v = int.tryParse('FF$cleaned', radix: 16);
      if (v != null) _updateHsl(HSLColor.fromColor(Color(v)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsl.toColor();
    final h = _hsl.hue;
    final s = _hsl.saturation;
    final l = _hsl.lightness;

    return AlertDialog(
      title: Text(widget.name),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live preview
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(height: 20),
            _buildSlider('H', h, 0, 360, (v) => _updateHsl(_hsl.withHue(v))),
            _buildSlider('S', s * 100, 0, 100, (v) => _updateHsl(_hsl.withSaturation(v / 100))),
            _buildSlider('L', l * 100, 0, 100, (v) => _updateHsl(_hsl.withLightness(v / 100))),
            const SizedBox(height: 12),
            TextField(
              controller: _hexCtrl,
              decoration: const InputDecoration(
                prefixText: '#',
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Hex',
              ),
              onSubmitted: _applyHex,
              onEditingComplete: () => _applyHex(_hexCtrl.text),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _hsl.toColor()),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
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
          child: Text(
            value.toStringAsFixed(0),
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
