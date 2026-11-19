import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../views/tab_strip_view.dart';
import 'notes_adapter.dart';

class TabsAdapter extends StatefulAdapterWidget {
  const TabsAdapter({super.key});

  static const List<({String id, String label})> tabs = [
    (id: 'tab1', label: 'Tab 1'),
    (id: 'tab2', label: 'Tab 2'),
  ];

  @override
  State<TabsAdapter> createState() => _TabsAdapterState();

  static Widget assemble(
    List<({String id, String label})> tabs,
    String active,
    ValueChanged<String> onSelect,
    Widget body,
  ) {
    return TabStripView(
      tabs: tabs,
      active: active,
      onSelect: onSelect,
      body: body,
    );
  }
}

class _TabsAdapterState extends State<TabsAdapter> {
  String _active = 'tab1';

  @override
  Widget build(BuildContext context) {
    return TabsAdapter.assemble(
      TabsAdapter.tabs,
      _active,
      (id) => setState(() => _active = id),
      NotesAdapter(key: ValueKey(_active), tabId: _active),
    );
  }
}
