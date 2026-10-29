import 'package:flutter/material.dart';
import '../interfaces/color_palette.dart';
import '../utils/colorblind_simulator.dart';
import 'contrast_matrix_widget.dart';

/// A widget that shows how a palette looks to people with different types of color blindness.
class ColorblindMatrixWidget extends StatefulWidget {
  final IColorPalette palette;
  final bool showContrastMatrix;
  final double cellSize;
  
  const ColorblindMatrixWidget({
    super.key,
    required this.palette,
    this.showContrastMatrix = true,
    this.cellSize = 50.0,
  });
  
  @override
  State<ColorblindMatrixWidget> createState() => _ColorblindMatrixWidgetState();
}

class _ColorblindMatrixWidgetState extends State<ColorblindMatrixWidget> {
  ColorblindType? _selectedType;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with type selector
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color Blindness Simulation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'See how your palette appears to people with different types of color vision.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                
                // Type selector
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ColorblindType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return FilterChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ColorblindSimulator.getColorblindTypeName(type),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Text(
                            ColorblindSimulator.getPrevalence(type),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? type : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Comparison view
        if (_selectedType != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original palette
              Expanded(
                child: _buildPaletteSection('Normal Vision', widget.palette),
              ),
              
              const SizedBox(width: 16),
              
              // Simulated palette
              Expanded(
                child: _buildPaletteSection(
                  ColorblindSimulator.getColorblindTypeName(_selectedType!),
                  ColorblindSimulator.simulatePalette(widget.palette, _selectedType!),
                ),
              ),
            ],
          ),
        ] else ...[
          // Show all types in a grid when none selected
          _buildAllTypesGrid(),
        ],
      ],
    );
  }
  
  Widget _buildPaletteSection(String title, IColorPalette palette) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Color swatches
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: palette.colorIdentifiers.map((id) {
                final color = palette.getColor(id)!;
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
                            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
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
            
            // Contrast matrix if enabled
            if (widget.showContrastMatrix) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Contrast Matrix',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SimpleContrastMatrix(
                palette: palette,
                cellSize: widget.cellSize * 0.8,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAllTypesGrid() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Color Blindness Types',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap any type above to see a detailed comparison.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            
            // Grid of all types
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: ColorblindType.values.length,
              itemBuilder: (context, index) {
                final type = ColorblindType.values[index];
                final simulatedPalette = ColorblindSimulator.simulatePalette(widget.palette, type);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ColorblindSimulator.getColorblindTypeName(type),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ColorblindSimulator.getPrevalence(type),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Mini color swatches
                        Expanded(
                          child: Row(
                            children: simulatedPalette.colorIdentifiers.take(6).map((id) {
                              final color = simulatedPalette.getColor(id)!;
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 2),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}