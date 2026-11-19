import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeleteSelectedIntent extends Intent {
  const DeleteSelectedIntent();
}

class NoteListView extends StatelessWidget {
  const NoteListView({
    super.key,
    required this.ids,
    required this.itemBuilder,
  });

  final List<String> ids;
  final Widget Function(String id) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.backspace, control: true):
            const DeleteSelectedIntent(),
      },
      child: Focus(
        autofocus: true,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final id in ids)
              KeyedSubtree(key: ValueKey('item-$id'), child: itemBuilder(id)),
          ],
        ),
      ),
    );
  }
}
