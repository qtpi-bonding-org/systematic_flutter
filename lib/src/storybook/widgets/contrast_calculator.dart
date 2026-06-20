// lib/src/storybook/widgets/contrast_calculator.dart
import 'package:flutter/material.dart';
import '../contrast.dart';

/// Pick two tokens -> WCAG ratio + AA/AAA badge. Plain Flutter chrome.
class ContrastCalculator extends StatefulWidget {
  const ContrastCalculator({super.key, required this.tokens});

  final Map<String, Color> tokens;

  @override
  State<ContrastCalculator> createState() => _ContrastCalculatorState();
}

class _ContrastCalculatorState extends State<ContrastCalculator> {
  late String _a = widget.tokens.keys.first;
  late String _b = widget.tokens.keys.length > 1
      ? widget.tokens.keys.elementAt(1)
      : widget.tokens.keys.first;

  @override
  Widget build(BuildContext context) {
    final ratio = contrastRatio(widget.tokens[_a]!, widget.tokens[_b]!);
    final rating = contrastRating(ratio);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dropdown(_a, (v) => setState(() => _a = v!)),
        _dropdown(_b, (v) => setState(() => _b = v!)),
        const SizedBox(height: 8),
        Text('${ratio.toStringAsFixed(2)} : 1'),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: rating == 'Fail' ? Colors.red.shade100 : Colors.green.shade100,
          child: Text(rating),
        ),
      ],
    );
  }

  Widget _dropdown(String value, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: value,
      onChanged: onChanged,
      items: [
        for (final key in widget.tokens.keys)
          DropdownMenuItem(value: key, child: Text(key)),
      ],
    );
  }
}
