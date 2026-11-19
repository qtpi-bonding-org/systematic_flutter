import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../scopes.dart';
import '../status/status_cubit.dart';
import '../views/status_view.dart';

class StatusAdapter extends AdapterWidget {
  const StatusAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return Connect<StatusCubit, StatusState, int>(
      select: selectTick,
      resolve: (c) => ScopeProvider.of<SessionScope>(c).status,
      debugLabel: 'status-view',
      builder: (ctx, tick, _) => assemble(tick),
    );
  }

  static Widget assemble(int tick) => StatusView(tick: tick);
}
