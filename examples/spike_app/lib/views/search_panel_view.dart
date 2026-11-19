import 'package:flutter/material.dart';
import 'package:systematic_ui/systematic_ui.dart';

import '../l10n/l10n_key_resolver.g.dart';
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
            hintText: context.resolveLabel(
              data.hasQuery
                  ? L10nKeys.searchHintActive
                  : L10nKeys.searchHintEmpty,
            ),
          ),
        ),
        Text(
          context.resolveLabel(
            data.online ? L10nKeys.statusOnline : L10nKeys.statusOffline,
          ),
        ),
      ],
    );
  }
}
