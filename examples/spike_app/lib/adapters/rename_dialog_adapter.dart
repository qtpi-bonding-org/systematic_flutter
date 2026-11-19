import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../rename/rename_form_cubit.dart';
import '../scopes.dart';
import '../views/rename_dialog_view.dart';

/// Rename dialog content. Owns the text controller and a per-dialog
/// [RenameFormCubit]; the BlocProvider closes the cubit when the dialog closes.
class RenameDialogAdapter extends StatefulAdapterWidget {
  const RenameDialogAdapter({
    super.key,
    required this.initial,
    required this.onSubmit,
  });

  final String initial;
  final ValueChanged<String> onSubmit;

  @override
  State<RenameDialogAdapter> createState() => _RenameDialogAdapterState();

  static Widget assemble(
    RenameFormData data,
    RenameFormActions actions,
    TextEditingController controller, {
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return RenameDialogView(
      data: data,
      controller: controller,
      onChanged: actions.edit,
      onSave: onSave,
      onCancel: onCancel,
    );
  }
}

class _RenameDialogAdapterState extends State<RenameDialogAdapter> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A dialog route is built under the Navigator, so it only sees scopes
    // provided ABOVE the Navigator (here SessionScope, above MaterialApp).
    // A scope provided inside a route (WorkspaceScope) is not visible, so
    // such values must be passed in as arguments by the adapter that opens
    // the dialog.
    return BlocProvider<RenameFormCubit>(
      create: (c) =>
          ScopeProvider.of<SessionScope>(c).newRenameForm(widget.initial),
      child: Connect<RenameFormCubit, RenameFormState, RenameFormData>(
        select: selectRenameForm,
        builder: (ctx, data, cubit) => RenameDialogAdapter.assemble(
          data,
          cubit,
          _controller,
          onSave: () {
            widget.onSubmit(_controller.text);
            Navigator.of(ctx).pop();
          },
          onCancel: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}
