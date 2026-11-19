import 'package:flutter/widgets.dart';

/// Whether a catalog entry is a reusable widget or a full screen.
enum CatalogKind { widget, screen }

/// One catalog item: a named widget or screen with one builder per state.
///
/// Keys of [states] are state labels (for example `enabled`, `disabled`).
class CatalogEntry {
  const CatalogEntry({
    required this.name,
    required this.kind,
    required this.states,
  });

  final String name;
  final CatalogKind kind;
  final Map<String, WidgetBuilder> states;
}
