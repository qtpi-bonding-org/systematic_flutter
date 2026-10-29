import 'package:flutter/material.dart';
import '../interfaces/color_palette.dart';
import '../implementations/app_color_palette.dart';
import 'contrast_matrix_widget.dart';
import 'color_picker_widget.dart';

/// A comprehensive palette editor with live contrast matrix preview.
/// 
/// Allows editing colors and seeing real-time updates to contrast ratios
/// and symmetric palette generation.
class PaletteEditorWidget extends StatefulWidget {
  final IColorPalette initialPalette;
  final ValueChanged<IColorPalette>? onPaletteChanged;
  final bool showContrastMatrix;
  
  const PaletteEditorWidget({
    super.key,
    required this.initialPalette,
    this.onPaletteChanged,
    this.showContrastMatrix = true,
  });
  
  @override
  State<PaletteEditorWidget> createState() => _PaletteEditorWidgetState();
}

class _PaletteEditorWidgetState extends State<PaletteEditorWidget> {
  late AppColorPalette _currentPalette;
  
  @override
  void initState() {
    super.initState();
    _currentPalette = widget.initialPalette is AppColorPalette 
        ? widget.initialPalette as AppColorPalette
        : AppColorPalette(colors: widget.initialPalette.colors);
  }
  
  void _updateColor(String identifier, Color color) {
    setState(() {
      _currentPalette = _currentPalette.updateColor(identifier, color);
    });
    widget.onPaletteChanged?.call(_currentPalette);
  }
  
  void _addColor() {
    final newId = 'color${_currentPalette.colors.length + 1}';
    setState(() {
      _currentPalette = _currentPalette.addColor(newId, Colors.blue);
    });
    widget.onPaletteChanged?.call(_currentPalette);
  }
  
  void _removeColor(String identifier) {
    setState(() {
      _currentPalette = _currentPalette.removeColor(identifier);
    });
    widget.onPaletteChanged?.call(_currentPalette);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color editor section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Color Palette Editor',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ElevatedButton.icon(
                      onPressed: _addColor,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Color'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Color swatches with pickers
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _currentPalette.colorIdentifiers.map((id) {
                    final color = _currentPalette.getColor(id)!;
                    return _buildColorEditor(id, color);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Contrast matrix section
        if (widget.showContrastMatrix) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contrast Matrix',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Numbers show contrast ratios. Colors show how text would look on backgrounds.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ContrastMatrixWidget(
                    lightPalette: _currentPalette,
                    cellSize: 50,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildColorEditor(String identifier, Color color) {
    return Column(
      children: [
        // Color swatch
        GestureDetector(
          onTap: () => _showColorPicker(identifier, color),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Center(
              child: Text(
                identifier,
                style: TextStyle(
                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Remove button
        if (_currentPalette.colors.length > 1)
          IconButton(
            onPressed: () => _removeColor(identifier),
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 16,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
      ],
    );
  }
  
  void _showColorPicker(String identifier, Color currentColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $identifier'),
        content: SizedBox(
          width: 300,
          child: ColorPickerWidget(
            initialColor: currentColor,
            onColorChanged: (color) => _updateColor(identifier, color),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

/// A compact palette preview widget.
class PalettePreviewWidget extends StatelessWidget {
  final IColorPalette palette;
  final double swatchSize;
  final VoidCallback? onTap;
  
  const PalettePreviewWidget({
    super.key,
    required this.palette,
    this.swatchSize = 40.0,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (palette.name != null) ...[
              Text(
                palette.name!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: palette.colorIdentifiers.map((id) {
                final color = palette.getColor(id)!;
                return Container(
                  width: swatchSize,
                  height: swatchSize,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}