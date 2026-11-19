import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../scopes.dart';
import '../workspace/workspace_cubit.dart';

/// Provides a [WorkspaceScope] for the selected workspace.
///
/// The ScopeProvider is keyed by the workspace id, so a switch disposes the
/// old scope (closing its notes cubits) and builds a new one for the subtree.
class WorkspaceHostAdapter extends AdapterWidget {
  const WorkspaceHostAdapter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Connect<WorkspaceCubit, String, String>(
      select: selectWorkspaceId,
      resolve: (c) => ScopeProvider.of<SessionScope>(c).workspace,
      builder: (ctx, id, _) {
        final notesSource = ScopeProvider.of<SessionScope>(ctx).notesSource;
        return ScopeProvider<WorkspaceScope>(
          key: ValueKey(id),
          create: () => WorkspaceScope(id, notesSource),
          child: child,
        );
      },
    );
  }
}
