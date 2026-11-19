import 'package:flutter/material.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.id,
    required this.title,
    required this.selected,
    required this.trailing,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
  });

  final String id;
  final String title;
  final bool selected;
  final Widget trailing;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('tile-$id'),
      selected: selected,
      onTap: onSelect,
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          trailing,
          IconButton(
            key: ValueKey('rename-$id'),
            tooltip: 'Rename',
            icon: const Icon(Icons.edit),
            onPressed: onRename,
          ),
          IconButton(
            key: ValueKey('delete-$id'),
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
