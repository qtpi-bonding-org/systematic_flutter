import 'dart:async';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../scopes.dart';
import '../search/search_cubit.dart';
import '../status/status_cubit.dart';
import '../views/search_panel_view.dart';

class SearchAdapter extends StatefulAdapterWidget {
  const SearchAdapter({super.key});

  @override
  State<SearchAdapter> createState() => _SearchAdapterState();

  static Widget assemble(
    SearchPanelData data,
    SearchActions actions,
    TextEditingController controller,
  ) {
    return SearchPanelView(
      data: data,
      controller: controller,
      onQuery: actions.setQuery,
    );
  }
}

class _SearchAdapterState extends State<SearchAdapter> {
  late final TextEditingController _controller;
  late final StreamSubscription<SearchState> _sub;

  @override
  void initState() {
    super.initState();
    final search = ScopeProvider.of<SessionScope>(context).search;
    _controller = TextEditingController(text: search.state.query);
    // A query changed elsewhere (not by typing) is copied into the field.
    // Setting the controller does not fire onChanged, so no feedback loop.
    _sub = search.stream.listen((s) {
      if (s.query == _controller.text) return;
      _controller.value = TextEditingValue(
        text: s.query,
        selection: TextSelection.collapsed(offset: s.query.length),
      );
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Connect2<SearchCubit, SearchState, StatusCubit, StatusState,
        SearchPanelData>(
      select: selectSearchPanel,
      resolve1: (c) => ScopeProvider.of<SessionScope>(c).search,
      resolve2: (c) => ScopeProvider.of<SessionScope>(c).status,
      debugLabel: 'search-panel',
      builder: (ctx, data, search, status) =>
          SearchAdapter.assemble(data, search, _controller),
    );
  }
}
