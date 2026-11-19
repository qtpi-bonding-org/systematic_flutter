import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'flow/flow_cubit.dart';
import 'notes/notes_cubit.dart';
import 'rename/rename_form_cubit.dart';
import 'search/search_cubit.dart';
import 'status/status_cubit.dart';
import 'tabs/tabs_cubit.dart';
import 'workspace/workspace_cubit.dart';

/// Lives for the whole app run.
class SessionScope extends AppScope {
  SessionScope({Duration tick = const Duration(seconds: 1)}) {
    search = own(SearchCubit());
    status = own(StatusCubit(interval: tick));
    workspace = own(WorkspaceCubit());
  }

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
  WorkspaceScope(this.id) {
    tabs = own(TabsCubit());
  }

  final String id;
  late final TabsCubit tabs;
  final Map<String, NotesCubit> _notes = <String, NotesCubit>{};

  NotesCubit notesFor(String tabId) => _notes.putIfAbsent(
        tabId,
        () => own(NotesCubit(seedNotes(id, tabId))),
      );
}

/// Lives while the start/confirm flow is on screen.
class FlowScope extends AppScope {
  FlowScope() {
    flow = own(FlowCubit());
  }

  late final FlowCubit flow;
}
