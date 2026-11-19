import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const kTabs = <({String id, String label})>[
  (id: 'tab1', label: 'Tab 1'),
  (id: 'tab2', label: 'Tab 2'),
];

abstract class TabsActions {
  void select(String id);
}

/// The active tab id. Lives in the workspace scope.
class TabsCubit extends Cubit<String> implements TabsActions {
  TabsCubit() : super('tab1');

  @override
  void select(String id) => emit(id);
}

@immutable
class TabStripData {
  const TabStripData({required this.tabs, required this.active});

  final List<({String id, String label})> tabs;
  final String active;

  @override
  bool operator ==(Object other) =>
      other is TabStripData &&
      listEquals(other.tabs, tabs) &&
      other.active == active;

  @override
  int get hashCode => Object.hash(Object.hashAll(tabs), active);
}

TabStripData selectTabStrip(String active) =>
    TabStripData(tabs: kTabs, active: active);
