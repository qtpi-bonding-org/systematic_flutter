// lib/src/storybook/widgets/contrast_grid.dart
import 'package:flutter/material.dart';
import '../contrast.dart';

/// N×N WCAG contrast matrix for all token pairs.
///
/// Each cell renders the BG/FG color combination and shows the contrast ratio
/// as a large number — no "Aa" sample text. Wrapped in [InteractiveViewer] so
/// the user can pinch-zoom and pan without the surrounding panel scrolling.
class ContrastGrid extends StatelessWidget {
  const ContrastGrid({super.key, required this.tokens});

  final Map<String, Color> tokens;

  @override
  Widget build(BuildContext context) {
    final entries = tokens.entries.toList();
    const cellSize = 68.0;
    const labelW = 110.0;
    const headerH = 88.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 14,
            children: const [
              _LegendChip(color: Color(0xFF4CAF50), label: 'AAA ≥7'),
              _LegendChip(color: Color(0xFF8BC34A), label: 'AA ≥4.5'),
              _LegendChip(color: Color(0xFFFF9800), label: 'AA Large ≥3'),
              _LegendChip(color: Color(0xFFE53935), label: 'Fail'),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            minScale: 0.25,
            maxScale: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column headers — FG token names rotated + colour dots
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: labelW),
                      for (final fg in entries)
                        SizedBox(
                          width: cellSize,
                          height: headerH,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: Text(
                                      fg.key,
                                      style: const TextStyle(fontSize: 9),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: fg.value,
                                  border: Border.all(color: Colors.white24),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // BG rows
                  for (final bg in entries)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: labelW,
                          height: cellSize + 2,
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: bg.value,
                                  border: Border.all(color: Colors.white24),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  bg.key,
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final fg in entries)
                          _ContrastCell(bg: bg.value, fg: fg.value, size: cellSize),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContrastCell extends StatelessWidget {
  const _ContrastCell({required this.bg, required this.fg, required this.size});

  final Color bg;
  final Color fg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ratio = contrastRatio(bg, fg);
    final borderColor = ratio >= 7.0
        ? const Color(0xFF4CAF50)
        : ratio >= 4.5
            ? const Color(0xFF8BC34A)
            : ratio >= 3.0
                ? const Color(0xFFFF9800)
                : const Color(0xFFE53935);

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          ratio.toStringAsFixed(1),
          style: TextStyle(
            color: fg,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
