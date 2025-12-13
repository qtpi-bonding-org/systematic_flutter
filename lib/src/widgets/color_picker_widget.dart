import 'package:flutter/material.dart';

/// A simple color picker widget for editing individual colors.
class ColorPickerWidget extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  
  const ColorPickerWidget({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });
  
  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late HSLColor _hslColor;
  
  @override
  void initState() {
    super.initState();
    _hslColor = HSLColor.fromColor(widget.initialColor);
  }
  
  void _updateColor() {
    widget.onColorChanged(_hslColor.toColor());
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color preview
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: _hslColor.toColor(),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Hue slider
        _buildSlider(
          'Hue',
          _hslColor.hue,
          0.0,
          360.0,
          (value) {
            setState(() {
              _hslColor = _hslColor.withHue(value);
            });
            _updateColor();
          },
        ),
        
        // Saturation slider
        _buildSlider(
          'Saturation',
          _hslColor.saturation,
          0.0,
          1.0,
          (value) {
            setState(() {
              _hslColor = _hslColor.withSaturation(value);
            });
            _updateColor();
          },
        ),
        
        // Lightness slider
        _buildSlider(
          'Lightness',
          _hslColor.lightness,
          0.0,
          1.0,
          (value) {
            setState(() {
              _hslColor = _hslColor.withLightness(value);
            });
            _updateColor();
          },
        ),
        
        const SizedBox(height: 16),
        
        // Hex input
        _buildHexInput(),
      ],
    );
  }
  
  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                value.toStringAsFixed(label == 'Hue' ? 0 : 2),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildHexInput() {
    final hexValue = _hslColor.toColor().value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hex Color', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: hexValue,
          decoration: const InputDecoration(
            prefixText: '#',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) {
            if (value.length == 6) {
              try {
                final color = Color(int.parse('FF$value', radix: 16));
                setState(() {
                  _hslColor = HSLColor.fromColor(color);
                });
                _updateColor();
              } catch (e) {
                // Invalid hex color, ignore
              }
            }
          },
        ),
      ],
    );
  }
}

/// Predefined color swatches for quick selection.
class ColorSwatchPicker extends StatelessWidget {
  final ValueChanged<Color> onColorSelected;
  
  const ColorSwatchPicker({
    super.key,
    required this.onColorSelected,
  });
  
  static const List<Color> _commonColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];
  
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _commonColors.map((color) {
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
          ),
        );
      }).toList(),
    );
  }
}