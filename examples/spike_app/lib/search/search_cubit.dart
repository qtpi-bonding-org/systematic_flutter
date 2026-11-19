import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../status/status_cubit.dart';

@immutable
class SearchState {
  const SearchState({required this.query});

  final String query;

  @override
  bool operator ==(Object other) =>
      other is SearchState && other.query == query;

  @override
  int get hashCode => query.hashCode;
}

abstract class SearchActions {
  void setQuery(String query);
}

class SearchCubit extends Cubit<SearchState> implements SearchActions {
  SearchCubit() : super(const SearchState(query: ''));

  @override
  void setQuery(String query) => emit(SearchState(query: query));
}

@immutable
class SearchPanelData {
  const SearchPanelData({required this.hasQuery, required this.online});

  final bool hasQuery;
  final bool online;

  @override
  bool operator ==(Object other) =>
      other is SearchPanelData &&
      other.hasQuery == hasQuery &&
      other.online == online;

  @override
  int get hashCode => Object.hash(hasQuery, online);
}

SearchPanelData selectSearchPanel(SearchState s, StatusState st) =>
    SearchPanelData(hasQuery: s.query.isNotEmpty, online: st.online);
