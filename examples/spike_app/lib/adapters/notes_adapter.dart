import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../notes/notes_cubit.dart';
import '../scopes.dart';
import '../views/note_list_view.dart';
import 'note_tile_adapter.dart';
import 'confirm_and_delete.dart';

class NotesAdapter extends AdapterWidget {
  const NotesAdapter({super.key, required this.tabId});

  final String tabId;

  @override
  Widget build(BuildContext context) {
    return Connect<NotesCubit, NotesState, NoteListData>(
      select: selectNoteIds,
      resolve: (c) => ScopeProvider.of<WorkspaceScope>(c).notesFor(tabId),
      debugLabel: 'note-list:$tabId',
      builder: (ctx, data, cubit) => assemble(
        tabId,
        data,
        (id) => NoteTileAdapter(
          key: ValueKey('$tabId/$id'),
          tabId: tabId,
          id: id,
        ),
        onDeleteSelected: () {
          final id = cubit.state.selectedId;
          if (id != null) confirmAndDelete(ctx, cubit, id);
        },
      ),
    );
  }

  static Widget assemble(
    String tabId,
    NoteListData data,
    Widget Function(String id) itemBuilder, {
    required VoidCallback onDeleteSelected,
  }) {
    return Actions(
      actions: <Type, Action<Intent>>{
        DeleteSelectedIntent: CallbackAction<DeleteSelectedIntent>(
          onInvoke: (_) {
            onDeleteSelected();
            return null;
          },
        ),
      },
      child: NoteListView(ids: data.ids, itemBuilder: itemBuilder),
    );
  }
}
