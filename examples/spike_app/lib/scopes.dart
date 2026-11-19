import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'notes/notes_source.dart';
import 'flow/flow_cubit.dart';
import 'notes/notes_cubit.dart';
import 'rename/rename_form_cubit.dart';
import 'search/search_cubit.dart';
import 'status/status_cubit.dart';
import 'tabs/tabs_cubit.dart';
import 'workspace/workspace_cubit.dart';

/// Lives for the whole app run.
class SessionScope extends AppScope {
  SessionScope({
    required this.notesSource,
    required this.ui,
    Duration tick = const Duration(seconds: 1),
  }) {
    search = own(SearchCubit());
    status = own(StatusCubit(interval: tick));
    workspace = own(WorkspaceCubit());
  }

  final NotesSource notesSource;
  final IUiFlowService ui;

  late final SearchCubit search;
  late final StatusCubit status;
  late final WorkspaceCubit workspace;

  /// A new rename form. Not owned by this scope: the rename dialog's
  /// BlocProvider closes it when the dialog closes.
  RenameFormCubit newRenameForm(String initial) => RenameFormCubit(initial);
}

/// Lives while one workspace is selected. Notes cubits and the active tab
/// are per workspace.
class WorkspaceScope extends AppScope {
  WorkspaceScope(this.id, this.notesSource) {
    tabs = own(TabsCubit(onClose: closeNotes));
  }

  final String id;
  final NotesSource notesSource;
  late final TabsCubit tabs;
  final Map<String, NotesCubit> _notes = <String, NotesCubit>{};

  /// The notes of [tabId]. The first call starts loading them.
  NotesCubit notesFor(String tabId) => _notes.putIfAbsent(
        tabId,
        () => own(NotesCubit(notesSource, id, tabId)..load()),
      );

  /// Releases the notes of a closed tab. A tab never opened has none.
  void closeNotes(String tabId) {
    final c = _notes.remove(tabId);
    if (c != null) release(c);
  }
}

/// Lives while the start/confirm flow is on screen.
class FlowScope extends AppScope {
  FlowScope() {
    flow = own(FlowCubit());
  }

  late final FlowCubit flow;
}
