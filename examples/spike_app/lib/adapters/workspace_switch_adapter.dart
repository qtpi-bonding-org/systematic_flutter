import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../scopes.dart';
import '../views/workspace_switch_view.dart';
import '../workspace/workspace_cubit.dart';

class WorkspaceSwitchAdapter extends AdapterWidget {
  const WorkspaceSwitchAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return Connect<WorkspaceCubit, String, String>(
      select: selectWorkspaceId,
      resolve: (c) => ScopeProvider.of<SessionScope>(c).workspace,
      builder: (ctx, id, cubit) => assemble(
        WorkspaceSwitchData(current: id, options: const ['A', 'B']),
        cubit,
      ),
    );
  }

  static Widget assemble(WorkspaceSwitchData data, WorkspaceActions actions) {
    return WorkspaceSwitchView(data: data, onSelect: actions.switchTo);
  }
}
