import 'package:flutter/foundation.dart';

import '../notes/notes_cubit.dart';
import '../search/search_cubit.dart';

/// Everything the home screen shows, as one value. The catalog builds the
/// screen from these samples; the live route builds it from live adapters.
@immutable
class HomeScreenData {
  const HomeScreenData({required this.list, required this.search});

  final NoteListData list;
  final SearchPanelData search;

  /// One entry per screen state. The list states reuse the list's own
  /// samples, so the screen and the list entry always show the same data.
  static Map<String, HomeScreenData> samples() {
    final search = SearchPanelData.samples()['empty-online']!;
    final lists = NoteListData.samples();
    return {
      'default': HomeScreenData(list: lists['full']!, search: search),
      'list loading': HomeScreenData(list: lists['loading']!, search: search),
      'list error': HomeScreenData(list: lists['error']!, search: search),
      'empty': HomeScreenData(list: lists['empty']!, search: search),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is HomeScreenData && other.list == list && other.search == search;

  @override
  int get hashCode => Object.hash(list, search);
}
