import 'package:flutter/material.dart';
import '../interfaces/color_palette.dart';
import '../utils/contrast_calculator.dart';
import '../utils/colorblind_simulator.dart';

/// A widget that displays a contrast matrix for a color palette.
/// 
/// Shows all color combinations with contrast ratios and accessibility grades.
/// Supports colorblind simulation modes to test accessibility.
class ContrastMatrixWidget extends StatefulWidget {
  final IColorPalette lightPalette;
  final IColorPalette? darkPalette;
  final double cellSize;
  final bool showAccessibilityGrades;
  final bool showColorblindModes;
  
  const ContrastMatrixWidget({
    super.key,
    required this.lightPalette,
    this.darkPalette,
    this.cellSize = 60.0,
    this.showAccessibilityGrades = true,
    this.showColorblindModes = true,
  });
  
  @override
  State<ContrastMatrixWidget> createState() => _ContrastMatrixWidgetState();
}

class _ContrastMatrixWidgetState extends State<ContrastMatrixWidget> {
  ColorblindType? _selectedColorblindType;
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.darkPalette ?? widget.lightPalette.symmetricPalette;
    final currentPalette = _isDarkMode ? dark : widget.lightPalette;
    
    // Apply colorblind simulation if selected
    final displayPalette = _selectedColorblindType != null
        ? ColorblindSimulator.simulatePalette(currentPalette, _selectedColorblindType!)
        : currentPalette;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls
        if (widget.showColorblindModes) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contrast Matrix Controls',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Theme mode toggle
                  Row(
                    children: [
                      Text('Theme: '),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Light')),
                          ButtonSegment(value: true, label: Text('Dark')),
                        ],
                        selected: {_isDarkMode},
                        onSelectionChanged: (Set<bool> selection) {
                          setState(() {
                            _isDarkMode = selection.first;
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Colorblind mode selector
                  Text('Vision Type: '),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Normal vision chip
                      FilterChip(
                        label: const Text('Normal Vision'),
                        selected: _selectedColorblindType == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedColorblindType = selected ? null : _selectedColorblindType;
                          });
                        },
                      ),
                      
                      // Colorblind type chips
                      ...ColorblindType.values.map((type) {
                        final isSelected = _selectedColorblindType == type;
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
                              _selectedColorblindType = selected ? type : null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Matrix display
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with current mode
                Text(
                  _buildMatrixTitle(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // The actual matrix
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildMatrix(displayPalette),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  String _buildMatrixTitle() {
    final themeMode = _isDarkMode ? 'Dark' : 'Light';
    final visionType = _selectedColorblindType != null
        ? ColorblindSimulator.getColorblindTypeName(_selectedColorblindType!)
        : 'Normal Vision';
    return '$themeMode Mode - $visionType';
  }
  
  Widget _buildMatrix(IColorPalette palette) {
    final colorIds = palette.colorIdentifiers;
    
    return Column(
      children: [
        // Header row with color swatches
        Row(
          children: [
            SizedBox(width: widget.cellSize, height: widget.cellSize), // Empty corner
            ...colorIds.map((id) => _buildHeaderCell(palette, id)),
          ],
        ),
        
        // Data rows
        ...colorIds.map((backgroundId) => _buildDataRow(palette, backgroundId, colorIds)),
      ],
    );
  }
  
  Widget _buildHeaderCell(IColorPalette palette, String colorId) {
    final color = palette.getColor(colorId)!;
    
    return Container(
      width: widget.cellSize,
      height: widget.cellSize,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          colorId,
          style: TextStyle(
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  Widget _buildDataRow(IColorPalette palette, String backgroundId, List<String> colorIds) {
    final backgroundColor = palette.getColor(backgroundId)!;
    
    return Row(
      children: [
        // Row header (background color swatch)
        Container(
          width: widget.cellSize,
          height: widget.cellSize,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              backgroundId,
              style: TextStyle(
                color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        // Contrast ratio cells
        ...colorIds.map((foregroundId) => _buildContrastCell(
          palette, 
          foregroundId, 
          backgroundId,
        )),
      ],
    );
  }
  
  Widget _buildContrastCell(IColorPalette palette, String foregroundId, String backgroundId) {
    final foregroundColor = palette.getColor(foregroundId)!;
    final backgroundColor = palette.getColor(backgroundId)!;
    
    final ratio = ContrastCalculator.contrastRatio(foregroundColor, backgroundColor);
    final grade = ContrastCalculator.getAccessibilityGrade(foregroundColor, backgroundColor);
    
    // Determine text color for readability
    final textColor = backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    
    return Container(
      width: widget.cellSize,
      height: widget.cellSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contrast ratio
            Text(
              ratio.toStringAsFixed(1),
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Accessibility grade (if enabled)
            if (widget.showAccessibilityGrades) ...[
              const SizedBox(height: 2),
              Text(
                grade,
                style: TextStyle(
                  color: textColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A simplified contrast matrix that shows only essential information.
class SimpleContrastMatrix extends StatelessWidget {
  final IColorPalette palette;
  final double cellSize;
  
  const SimpleContrastMatrix({
    super.key,
    required this.palette,
    this.cellSize = 40.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorIds = palette.colorIdentifiers;
    
    return Column(
      children: colorIds.map((backgroundId) {
        return Row(
          children: colorIds.map((foregroundId) {
            final foregroundColor = palette.getColor(foregroundId)!;
            final backgroundColor = palette.getColor(backgroundId)!;
            final ratio = ContrastCalculator.contrastRatio(foregroundColor, backgroundColor);
            
            return Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: Center(
                child: Text(
                  ratio.toStringAsFixed(1),
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}