import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../flow/flow_cubit.dart';
import '../scopes.dart';
import '../views/confirm_view.dart';
import '../views/start_view.dart';

class FlowStartAdapter extends AdapterWidget {
  const FlowStartAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return Connect<FlowCubit, FlowState, FlowNameData>(
      select: selectFlowName,
      resolve: (c) => ScopeProvider.of<FlowScope>(c).flow,
      builder: (ctx, data, cubit) => assemble(
        data,
        cubit,
        onNext: () => GoRouter.of(ctx).go('/start/confirm'),
      ),
    );
  }

  static Widget assemble(
    FlowNameData data,
    FlowActions actions, {
    required VoidCallback onNext,
  }) {
    return StartView(
      data: data,
      onNameChanged: actions.setName,
      onNext: onNext,
    );
  }
}

class FlowConfirmAdapter extends AdapterWidget {
  const FlowConfirmAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return Connect<FlowCubit, FlowState, FlowNameData>(
      select: selectFlowName,
      resolve: (c) => ScopeProvider.of<FlowScope>(c).flow,
      builder: (ctx, data, _) => assemble(
        data,
        onBack: () => GoRouter.of(ctx).go('/start'),
      ),
    );
  }

  static Widget assemble(FlowNameData data, {required VoidCallback onBack}) {
    return ConfirmView(data: data, onBack: onBack);
  }
}
