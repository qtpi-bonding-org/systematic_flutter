import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';

import '../probe.dart';
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
    return probe(
      'search-panel',
      SearchPanelView(
        data: data,
        controller: controller,
        onQuery: actions.setQuery,
      ),
    );
  }
}

class _SearchAdapterState extends State<SearchAdapter> {
  TextEditingController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller ??= TextEditingController(
      text: ScopeProvider.of<SessionScope>(context).search.state.query,
    );
    return Connect2<SearchCubit, SearchState, StatusCubit, StatusState,
        SearchPanelData>(
      select: selectSearchPanel,
      resolve1: (c) => ScopeProvider.of<SessionScope>(c).search,
      resolve2: (c) => ScopeProvider.of<SessionScope>(c).status,
      builder: (ctx, data, search, status) =>
          SearchAdapter.assemble(data, search, controller),
    );
  }
}
