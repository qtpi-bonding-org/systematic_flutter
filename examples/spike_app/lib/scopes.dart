import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'flow/flow_cubit.dart';
import 'notes/notes_cubit.dart';
import 'rename/rename_form_cubit.dart';
import 'search/search_cubit.dart';
import 'status/status_cubit.dart';
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

  /// Every rename form issued, in order. Test visibility only.
  ///
  /// Forms are not owned by this scope: the rename dialog's BlocProvider
  /// closes each one when the dialog closes.
  final List<RenameFormCubit> issuedRenameForms = [];

  RenameFormCubit newRenameForm(String initial) {
    final form = RenameFormCubit(initial);
    issuedRenameForms.add(form);
    return form;
  }
}

/// Lives while one workspace is selected. Notes cubits are per tab.
class WorkspaceScope extends AppScope {
  WorkspaceScope(this.id);

  final String id;
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
