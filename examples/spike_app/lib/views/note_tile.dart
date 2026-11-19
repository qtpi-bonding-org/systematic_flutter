import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

import '../l10n/l10n_key_resolver.g.dart';
import '../notes/notes_cubit.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.data,
    required this.trailing,
    required this.onSelect,
    required this.onDelete,
    required this.onRename,
  });

  final NoteTileData data;
  final Widget trailing;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('tile-pad-${data.id}'),
      padding: context.padding.listItem,
      child: ListTile(
        key: ValueKey('tile-${data.id}'),
        selected: data.selected,
        onTap: onSelect,
        title: Text(data.title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            trailing,
            IconButton(
              key: ValueKey('rename-${data.id}'),
              tooltip: context.resolveLabel(L10nKeys.noteRename),
              icon: const Icon(Icons.edit),
              onPressed: onRename,
            ),
            IconButton(
              key: ValueKey('delete-${data.id}'),
              tooltip: context.resolveLabel(L10nKeys.noteDelete),
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
