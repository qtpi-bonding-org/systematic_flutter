import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../notes/notes_cubit.dart';
import '../scopes.dart';
import '../views/note_list_view.dart';
import 'confirm_and_delete.dart';
import 'note_tile_adapter.dart';
import 'notes_message_mapper.dart';

class NotesAdapter extends AdapterWidget {
  const NotesAdapter({super.key, required this.tabId});

  final String tabId;

  @override
  Widget build(BuildContext context) {
    return Connect<NotesCubit, NotesState, NoteListData>(
      select: selectNoteIds,
      resolve: (c) => ScopeProvider.of<WorkspaceScope>(c).notesFor(tabId),
      debugLabel: 'note-list:$tabId',
      builder: (ctx, data, cubit) => UiFlowStateListener<NotesCubit, NotesState>(
        bloc: cubit,
        mapper: NotesMessageMapper.create(),
        uiService: ScopeProvider.of<SessionScope>(ctx).ui,
        showLoadingOverlay: false,
        showSuccessMessages: true,
        listenWhen: _listenWhen,
        child: assemble(
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
          onRetry: cubit.reload,
        ),
      ),
    );
  }

  /// A toast fires on a new event (identity), a status change or a new error.
  static bool _listenWhen(NotesState previous, NotesState current) =>
      !identical(previous.event, current.event) ||
      previous.status != current.status ||
      previous.error != current.error;

  static Widget assemble(
    String tabId,
    NoteListData data,
    Widget Function(String id) itemBuilder, {
    required VoidCallback onDeleteSelected,
    required VoidCallback onRetry,
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
      child: NoteListView(
        data: data,
        itemBuilder: itemBuilder,
        onRetry: onRetry,
      ),
    );
  }
}
