import 'package:flutter/material.dart';

class WorkspaceSwitchView extends StatelessWidget {
  const WorkspaceSwitchView({
    super.key,
    required this.current,
    required this.options,
    required this.onSelect,
  });

  final String current;
  final List<String> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final id in options)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: id == current
                ? FilledButton(
                    key: ValueKey('ws-$id'),
                    onPressed: () => onSelect(id),
                    child: Text(id),
                  )
                : OutlinedButton(
                    key: ValueKey('ws-$id'),
                    onPressed: () => onSelect(id),
                    child: Text(id),
                  ),
          ),
      ],
    );
  }
}
