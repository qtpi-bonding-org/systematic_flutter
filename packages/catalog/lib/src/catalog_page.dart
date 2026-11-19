import 'package:flutter/material.dart';

import 'catalog_entry.dart';
import 'catalog_tokens.dart';

/// Logical size of a screen, as it would render on a 390x844 phone.
const Size _screenSize = Size(390, 844);

/// Screens are shown at this fraction of their logical size.
const double _screenFrameScale = 0.4;

/// Preset colours offered in the side panel, in key order.
const List<Color> _swatches = [
  Colors.indigo,
  Colors.teal,
  Colors.orange,
  Colors.pink,
];

/// Dev page showing every widget and screen state in light and dark, with
/// live theme tokens adjustable from a side panel.
///
/// Place it under a `MaterialApp`.
class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.entries,
    required this.themeBuilder,
    this.fontFamilies = const ['Roboto'],
  });

  final List<CatalogEntry> entries;
  final ThemeData Function(CatalogTokens tokens, Brightness brightness)
      themeBuilder;
  final List<String> fontFamilies;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late CatalogTokens _tokens = CatalogTokens(
    fontFamily:
        widget.fontFamilies.isEmpty ? null : widget.fontFamilies.first,
  );

  void _update(CatalogTokens next) => setState(() => _tokens = next);

  @override
  Widget build(BuildContext context) {
    final widgets = widget.entries
        .where((e) => e.kind == CatalogKind.widget)
        .toList(growable: false);
    final screens = widget.entries
        .where((e) => e.kind == CatalogKind.screen)
        .toList(growable: false);

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Widgets', style: _heading(context)),
                  _tiles(widgets, context),
                  const SizedBox(height: 24),
                  Text('Screens', style: _heading(context)),
                  _tiles(screens, context),
                ],
              ),
            ),
          ),
          SizedBox(width: 260, child: _sidePanel(context)),
        ],
      ),
    );
  }

  TextStyle? _heading(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge;

  Widget _tiles(List<CatalogEntry> entries, BuildContext context) {
    final spacing = 16 * _tokens.spacingScale;
    final tiles = <Widget>[
      for (final entry in entries)
        for (final state in entry.states.entries)
          _tile(
            entry: entry,
            stateLabel: state.key,
            builder: state.value,
            isScreen: entry.kind == CatalogKind.screen,
          ),
    ];
    return Wrap(spacing: spacing, runSpacing: spacing, children: tiles);
  }

  Widget _tile({
    required CatalogEntry entry,
    required String stateLabel,
    required WidgetBuilder builder,
    required bool isScreen,
  }) {
    final id = '${entry.name}/$stateLabel';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${entry.name} / $stateLabel'),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pane(id: id, brightness: Brightness.light, isScreen: isScreen,
                builder: builder),
            const SizedBox(width: 12),
            _pane(id: id, brightness: Brightness.dark, isScreen: isScreen,
                builder: builder),
          ],
        ),
      ],
    );
  }

  Widget _pane({
    required String id,
    required Brightness brightness,
    required bool isScreen,
    required WidgetBuilder builder,
  }) {
    final caption = brightness == Brightness.light ? 'light' : 'dark';
    final content = _paneContent(brightness: brightness, builder: builder);
    final keyed = isScreen
        ? _screenFrame(key: Key('$id/$caption'), child: content)
        : ConstrainedBox(
            key: Key('$id/$caption'),
            constraints: const BoxConstraints(maxWidth: 360),
            child: content,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 2),
        keyed,
      ],
    );
  }

  /// Themed content for one pane. A state builder that throws renders an
  /// error tile instead of taking the whole page down.
  Widget _paneContent({
    required Brightness brightness,
    required WidgetBuilder builder,
  }) {
    return Theme(
      data: widget.themeBuilder(_tokens, brightness),
      child: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(_tokens.fontScale),
            ),
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Builder(
                builder: (inner) {
                  try {
                    return builder(inner);
                  } catch (e) {
                    return Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Fixed 0.4-scale frame: the screen is laid out at its logical 390x844
  /// size and scaled down to fit.
  Widget _screenFrame({required Key key, required Widget child}) {
    return SizedBox(
      key: key,
      width: _screenSize.width * _screenFrameScale,
      height: _screenSize.height * _screenFrameScale,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _screenSize.width,
          height: _screenSize.height,
          child: ClipRect(child: child),
        ),
      ),
    );
  }

  Widget _sidePanel(BuildContext context) {
    final tokens = _tokens;
    final fonts = widget.fontFamilies;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Seed colour'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < _swatches.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  key: Key('catalog.swatch.$i'),
                  onTap: () => _update(tokens.copyWith(seed: _swatches[i])),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _swatches[i],
                      shape: BoxShape.circle,
                      border: tokens.seed == _swatches[i]
                          ? Border.all(width: 3, color: Colors.black)
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Font family'),
        DropdownButton<String>(
          isExpanded: true,
          value: tokens.fontFamily,
          items: [
            for (final f in fonts) DropdownMenuItem(value: f, child: Text(f)),
          ],
          onChanged: (v) => _update(tokens.copyWith(fontFamily: v)),
        ),
        const SizedBox(height: 16),
        Text('Font scale: ${tokens.fontScale.toStringAsFixed(2)}'),
        Slider(
          key: const Key('catalog.fontScale'),
          min: 0.8,
          max: 1.4,
          value: tokens.fontScale,
          onChanged: (v) => _update(tokens.copyWith(fontScale: v)),
        ),
        const SizedBox(height: 16),
        Text('Spacing scale: ${tokens.spacingScale.toStringAsFixed(2)}'),
        Slider(
          key: const Key('catalog.spacingScale'),
          min: 0.75,
          max: 1.5,
          value: tokens.spacingScale,
          onChanged: (v) => _update(tokens.copyWith(spacingScale: v)),
        ),
      ],
    );
  }
}
