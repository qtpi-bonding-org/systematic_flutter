import 'package:flutter/material.dart';
import '../interfaces/color_palette.dart';
import '../implementations/app_color_palette.dart';
import 'palette_editor_widget.dart';
import 'contrast_matrix_widget.dart';

/// A comprehensive demo widget showcasing all flutter_color_palette features.
/// 
/// This widget provides:
/// - Interactive palette editing with real-time updates
/// - Automatic dark mode generation via luminance symmetry
/// - Live contrast matrix with colorblind simulation
/// - Example UI components showing palette usage
/// - Scientific colorblind accessibility testing
class PaletteDemoWidget extends StatefulWidget {
  final IColorPalette? initialPalette;
  final String? title;
  final String? description;
  final bool showPaletteEditor;
  final bool showContrastMatrix;
  final bool showExampleUsage;
  final bool showSymmetricComparison;
  
  const PaletteDemoWidget({
    super.key,
    this.initialPalette,
    this.title,
    this.description,
    this.showPaletteEditor = true,
    this.showContrastMatrix = true,
    this.showExampleUsage = true,
    this.showSymmetricComparison = true,
  });

  @override
  State<PaletteDemoWidget> createState() => _PaletteDemoWidgetState();
}

class _PaletteDemoWidgetState extends State<PaletteDemoWidget> {
  late IColorPalette _currentPalette;

  @override
  void initState() {
    super.initState();
    
    // Use provided palette or create a default one
    _currentPalette = widget.initialPalette ?? AppColorPalette.enumerated(
      colors: [
        const Color(0xFF1976D2), // Blue - primary
        const Color(0xFF388E3C), // Green - success
        const Color(0xFFF57C00), // Orange - warning
        const Color(0xFFD32F2F), // Red - error
        const Color(0xFF7B1FA2), // Purple - insights
        const Color(0xFF00796B), // Teal - wellness
      ],
      neutrals: [
        const Color(0xFF212121), // Dark text
        const Color(0xFF424242), // Medium dark
        const Color(0xFF757575), // Medium
        const Color(0xFFBDBDBD), // Light medium
        const Color(0xFFF5F5F5), // Light background
        const Color(0xFFFFFFFF), // Pure white
      ],
      name: 'Demo Palette',
      description: 'Interactive demonstration of the flutter_color_palette system',
      tags: ['demo', 'interactive', 'accessibility'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Description
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _currentPalette.getColor('color1'),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          if (widget.description != null) ...[
            Text(
              widget.description!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
          ],
          
          // Current Palette Overview
          _buildPaletteOverview(),
          
          if (widget.showSymmetricComparison) ...[
            const SizedBox(height: 24),
            _buildSymmetricComparison(),
          ],
          
          if (widget.showPaletteEditor) ...[
            const SizedBox(height: 24),
            _buildInteractiveEditor(),
          ],
          
          if (widget.showExampleUsage) ...[
            const SizedBox(height: 24),
            _buildExampleUsage(),
          ],
          
          if (widget.showContrastMatrix) ...[
            const SizedBox(height: 24),
            _buildAccessibilityTesting(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPaletteOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: _currentPalette.getColor('color1'),
                ),
                const SizedBox(width: 8),
                Text(
                  _currentPalette.name ?? 'Color Palette',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            if (_currentPalette.description != null) ...[
              const SizedBox(height: 8),
              Text(_currentPalette.description!),
            ],
            
            const SizedBox(height: 16),
            
            // Color swatches
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentPalette.colorIdentifiers.map((id) {
                final color = _currentPalette.getColor(id)!;
                return Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          id,
                          style: TextStyle(
                            color: color.computeLuminance() > 0.5 
                                ? Colors.black 
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      id,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSymmetricComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.brightness_6,
                  color: _currentPalette.getColor('color1'),
                ),
                const SizedBox(width: 8),
                Text(
                  'Automatic Dark Mode (Mathematical Symmetry)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Luminance inversion creates perfect dark mode automatically. Edit colors above to see real-time updates:',
            ),
            const SizedBox(height: 16),
            
            // Side-by-side comparison
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Light Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _currentPalette.colorIdentifiers.take(8).map((id) {
                          final color = _currentPalette.getColor(id)!;
                          return Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Text(
                                id.replaceAll('color', 'C').replaceAll('neutral', 'N'),
                                style: TextStyle(
                                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Auto Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _currentPalette.colorIdentifiers.take(8).map((id) {
                          final color = _currentPalette.symmetricPalette.getColor(id)!;
                          return Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Text(
                                id.replaceAll('color', 'C').replaceAll('neutral', 'N'),
                                style: TextStyle(
                                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInteractiveEditor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit,
                  color: _currentPalette.getColor('color1'),
                ),
                const SizedBox(width: 8),
                Text(
                  'Interactive Palette Editor',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Click on any color to edit it and see real-time updates throughout the demo:',
            ),
            const SizedBox(height: 16),
            
            PaletteEditorWidget(
              initialPalette: _currentPalette,
              onPaletteChanged: (newPalette) {
                setState(() {
                  _currentPalette = newPalette;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExampleUsage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: _currentPalette.getColor('color1'),
                ),
                const SizedBox(width: 8),
                Text(
                  'Live UI Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Example UI components that update in real-time as you edit colors:',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            
            // Example buttons using the palette
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPalette.getColor('color1'),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Primary Action'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPalette.getColor('color2'),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Success'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPalette.getColor('color3'),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Warning'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPalette.getColor('color4'),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Error'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccessibilityTesting() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.accessibility,
                  color: _currentPalette.getColor('color1'),
                ),
                const SizedBox(width: 8),
                Text(
                  'Interactive Accessibility Testing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Test your palette across different vision types with scientific colorblind simulation:',
            ),
            const SizedBox(height: 16),
            
            ContrastMatrixWidget(
              lightPalette: _currentPalette,
              showColorblindModes: true,
              showAccessibilityGrades: true,
              cellSize: 45,
            ),
          ],
        ),
      ),
    );
  }
}