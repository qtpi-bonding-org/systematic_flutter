import 'package:flutter/material.dart';

import '../search/search_cubit.dart';

class SearchPanelView extends StatelessWidget {
  const SearchPanelView({
    super.key,
    required this.data,
    required this.controller,
    required this.onQuery,
  });

  final SearchPanelData data;
  final TextEditingController controller;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const ValueKey('search-field'),
          controller: controller,
          onChanged: onQuery,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            hintText: data.hasQuery ? 'Searching notes' : 'Type to search',
          ),
        ),
        Text(data.online ? 'Online' : 'Offline'),
      ],
    );
  }
}
