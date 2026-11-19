import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:systematic_ui/systematic_ui.dart';

import '../l10n/l10n_key_resolver.g.dart';
import '../notes/notes_cubit.dart';

class DeleteSelectedIntent extends Intent {
  const DeleteSelectedIntent();
}

class NoteListView extends StatelessWidget {
  const NoteListView({
    super.key,
    required this.data,
    required this.itemBuilder,
    required this.onRetry,
  });

  final NoteListData data;
  final Widget Function(String id) itemBuilder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.backspace, control: true):
            const DeleteSelectedIntent(),
      },
      child: Focus(
        autofocus: true,
        child: switch (data) {
          NoteListLoading() => _loading(context),
          NoteListFailed(:final message) => _failed(context, message),
          NoteListLoaded(:final ids) when ids.isEmpty => _empty(context),
          NoteListLoaded(:final ids) => _list(ids),
        },
      ),
    );
  }

  Widget _loading(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            VSpace.x1,
            Text(context.resolveLabel(L10nKeys.notesLoading)),
          ],
        ),
      );

  Widget _failed(BuildContext context, L10nKey message) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.resolveLabel(message)),
            TextButton(
              onPressed: onRetry,
              child: Text(context.resolveLabel(L10nKeys.notesRetry)),
            ),
          ],
        ),
      );

  Widget _empty(BuildContext context) => Center(
        child: Text(context.resolveLabel(L10nKeys.notesEmpty)),
      );

  Widget _list(List<String> ids) => ListView(
        shrinkWrap: true,
        children: [
          for (final id in ids)
            KeyedSubtree(key: ValueKey('item-$id'), child: itemBuilder(id)),
        ],
      );
}
