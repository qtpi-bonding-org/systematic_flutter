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
    return Connect<FlowCubit, FlowState, String>(
      select: selectFlowName,
      resolve: (c) => ScopeProvider.of<FlowScope>(c).flow,
      builder: (ctx, name, cubit) => assemble(
        name,
        cubit,
        onNext: () => GoRouter.of(ctx).go('/start/confirm'),
      ),
    );
  }

  static Widget assemble(
    String name,
    FlowActions actions, {
    required VoidCallback onNext,
  }) {
    return StartView(
      name: name,
      onNameChanged: actions.setName,
      onNext: onNext,
    );
  }
}

class FlowConfirmAdapter extends AdapterWidget {
  const FlowConfirmAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return Connect<FlowCubit, FlowState, String>(
      select: selectFlowName,
      resolve: (c) => ScopeProvider.of<FlowScope>(c).flow,
      builder: (ctx, name, _) => assemble(
        name,
        onBack: () => GoRouter.of(ctx).go('/start'),
      ),
    );
  }

  static Widget assemble(String name, {required VoidCallback onBack}) {
    return ConfirmView(name: name, onBack: onBack);
  }
}
