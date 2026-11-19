import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../notes/notes_cubit.dart';
import '../scopes.dart';
import '../views/note_tile.dart';
import '../views/tag_chip.dart';
import 'rename_dialog_adapter.dart';
import 'confirm_and_delete.dart';

class NoteTileAdapter extends AdapterWidget {
  const NoteTileAdapter({super.key, required this.tabId, required this.id});

  final String tabId;
  final String id;

  @override
  Widget build(BuildContext context) {
    return ConnectFor<NotesCubit, NotesState, String, NoteTileData?>(
      arg: id,
      select: selectNote,
      resolve: (c) => ScopeProvider.of<WorkspaceScope>(c).notesFor(tabId),
      debugLabel: 'tile:$id',
      builder: (ctx, data, cubit) {
        if (data == null) return const SizedBox.shrink();
        return assemble(
          data,
          cubit,
          onRename: () => showDialog<void>(
            context: ctx,
            builder: (_) => RenameDialogAdapter(
              initial: data.title,
              onSubmit: (t) => cubit.rename(id, t),
            ),
          ),
          onDelete: () => confirmAndDelete(ctx, cubit, id),
        );
      },
    );
  }

  static Widget assemble(
    NoteTileData data,
    NotesActions actions, {
    required VoidCallback onRename,
    required VoidCallback onDelete,
  }) {
    return NoteTile(
      id: data.id,
      title: data.title,
      selected: data.selected,
      trailing: TagChip(
        label: data.tag,
        onTap: () => actions.cycleTag(data.id),
      ),
      onSelect: () => actions.select(data.id),
      onDelete: onDelete,
      onRename: onRename,
    );
  }
}
