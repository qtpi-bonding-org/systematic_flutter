import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/widgets.dart';

import '../scopes.dart';
import '../tabs/tabs_cubit.dart';
import '../views/tab_strip_view.dart';
import 'notes_adapter.dart';

class TabsAdapter extends AdapterWidget {
  const TabsAdapter({super.key});

  @override
  Widget build(BuildContext context) {
    return Connect<TabsCubit, String, TabStripData>(
      select: selectTabStrip,
      resolve: (c) => ScopeProvider.of<WorkspaceScope>(c).tabs,
      debugLabel: 'tabs',
      builder: (ctx, data, cubit) =>
          assemble(data, cubit, NotesAdapter(tabId: data.active)),
    );
  }

  static Widget assemble(TabStripData data, TabsActions actions, Widget body) {
    return TabStripView(
      tabs: data.tabs,
      active: data.active,
      onSelect: actions.select,
      onClose: actions.closeTab,
      body: body,
    );
  }
}
