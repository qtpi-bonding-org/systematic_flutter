import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../notes/notes_cubit.dart';
import '../probe.dart';
import '../scopes.dart';
import '../views/note_tile.dart';
import '../views/tag_chip.dart';
import 'rename_dialog_adapter.dart';
import 'ui_notes_actions.dart';

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
      builder: (ctx, data, cubit) {
        if (data == null) return const SizedBox.shrink();
        return assemble(
          data,
          UiNotesActions(ctx, cubit),
          onRename: () => showDialog<void>(
            context: ctx,
            builder: (_) => RenameDialogAdapter(
              initial: data.title,
              onSubmit: (t) => cubit.rename(id, t),
            ),
          ),
        );
      },
    );
  }

  static Widget assemble(
    NoteTileData data,
    NotesActions actions, {
    required VoidCallback onRename,
  }) {
    return probe(
      'tile:${data.id}',
      NoteTile(
        id: data.id,
        title: data.title,
        selected: data.selected,
        trailing: TagChip(
          label: data.tag,
          onTap: () => actions.cycleTag(data.id),
        ),
        onSelect: () => actions.select(data.id),
        onDelete: () => actions.delete(data.id),
        onRename: onRename,
      ),
    );
  }
}
