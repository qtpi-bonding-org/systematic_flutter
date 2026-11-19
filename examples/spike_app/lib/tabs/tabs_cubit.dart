import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n_key_resolver/runtime.dart';

import '../l10n/l10n_key_resolver.g.dart';

const kTabs = <({String id, Label label})>[
  (id: 'tab1', label: L10nKeys.tabOne),
  (id: 'tab2', label: L10nKeys.tabTwo),
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

  final List<({String id, Label label})> tabs;
  final String active;

  static Map<String, TabStripData> samples() => {
        'tab1': TabStripData(tabs: kTabs, active: 'tab1'),
        'tab2': TabStripData(tabs: kTabs, active: 'tab2'),
      };

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
