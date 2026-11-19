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

  /// One state per named sample, each built from that sample. Use this when
  /// a widget is driven by plain data: the sample name becomes the state label.
  static CatalogEntry fromSamples<T>({
    required String name,
    required CatalogKind kind,
    required Map<String, T> samples,
    required Widget Function(T) build,
  }) {
    return CatalogEntry(
      name: name,
      kind: kind,
      states: {
        for (final e in samples.entries)
          e.key: (BuildContext context) => build(e.value),
      },
    );
  }

  final String name;
  final CatalogKind kind;
  final Map<String, WidgetBuilder> states;
}
