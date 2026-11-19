import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

@immutable
class WorkspaceSwitchData {
  const WorkspaceSwitchData({required this.current, required this.options});

  final String current;
  final List<String> options;

  static Map<String, WorkspaceSwitchData> samples() => const {
        'A': WorkspaceSwitchData(current: 'A', options: ['A', 'B']),
        'B': WorkspaceSwitchData(current: 'B', options: ['A', 'B']),
      };

  @override
  bool operator ==(Object other) =>
      other is WorkspaceSwitchData &&
      other.current == current &&
      listEquals(other.options, options);

  @override
  int get hashCode => Object.hash(current, Object.hashAll(options));
}

class WorkspaceSwitchView extends StatelessWidget {
  const WorkspaceSwitchView({
    super.key,
    required this.data,
    required this.onSelect,
  });

  final WorkspaceSwitchData data;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final id in data.options)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.sizes.spaceHalf),
            child: id == data.current
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
