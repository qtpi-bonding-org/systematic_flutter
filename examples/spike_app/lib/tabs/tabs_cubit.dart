import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n_key_resolver/runtime.dart';

import '../l10n/l10n_key_resolver.g.dart';

const _idPrefix = 'tab';

String _tabId(int number) => '$_idPrefix$number';

/// The open tabs, in order, and which one is active. Immutable.
@immutable
class TabsState {
  const TabsState({required this.open, required this.active});

  final List<String> open;
  final String active;

  @override
  bool operator ==(Object other) =>
      other is TabsState &&
      listEquals(other.open, open) &&
      other.active == active;

  @override
  int get hashCode => Object.hash(Object.hashAll(open), active);
}

abstract class TabsActions {
  void select(String id);
  void newTab();
  void closeTab(String id);
}

/// The open tabs and the active one. Lives in the workspace scope.
class TabsCubit extends Cubit<TabsState> implements TabsActions {
  TabsCubit({required this.onClose})
      : super(const TabsState(open: ['tab1', 'tab2'], active: 'tab1'));

  /// Called with the id of a closed tab, so its notes cubit can be released.
  final void Function(String id) onClose;

  /// The number the next new tab gets. Never reused, so an id is unique for
  /// the life of the workspace.
  int _nextNumber = 3;

  @override
  void select(String id) {
    if (!state.open.contains(id)) return;
    emit(TabsState(open: state.open, active: id));
  }

  @override
  void newTab() {
    final id = _tabId(_nextNumber++);
    emit(TabsState(open: [...state.open, id], active: id));
  }

  /// Closes [id]. The last open tab cannot be closed. If [id] is active, the
  /// active tab moves to its next neighbour, else to its previous one.
  @override
  void closeTab(String id) {
    final index = state.open.indexOf(id);
    if (index < 0 || state.open.length < 2) return;
    final open = [...state.open]..removeAt(index);
    final active = id != state.active
        ? state.active
        : index < open.length
            ? open[index]
            : open[index - 1];
    emit(TabsState(open: open, active: active));
    onClose(id);
  }
}

/// What the tab strip shows. [canClose] is true while more than one tab is
/// open.
@immutable
class TabStripData {
  const TabStripData({required this.tabs, required this.active});

  final List<({String id, Label label})> tabs;
  final String active;

  bool get canClose => tabs.length > 1;

  static Map<String, TabStripData> samples() => {
        'one tab': _of(const ['tab1'], 'tab1'),
        'two tabs': _of(const ['tab1', 'tab2'], 'tab1'),
        'second active': _of(const ['tab1', 'tab2'], 'tab2'),
      };

  static TabStripData _of(List<String> ids, String active) => TabStripData(
        tabs: [for (final id in ids) (id: id, label: _tabLabel(id))],
        active: active,
      );

  @override
  bool operator ==(Object other) =>
      other is TabStripData &&
      listEquals(other.tabs, tabs) &&
      other.active == active;

  @override
  int get hashCode => Object.hash(Object.hashAll(tabs), active);
}

/// "Tab {n}", where n is the number in the id ('tab3' reads "Tab 3").
Label _tabLabel(String id) =>
    L10nKeys.tabNumber(number: int.parse(id.substring(_idPrefix.length)));

TabStripData selectTabStrip(TabsState state) => TabStripData(
      tabs: [for (final id in state.open) (id: id, label: _tabLabel(id))],
      active: state.active,
    );
