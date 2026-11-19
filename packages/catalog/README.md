# systematic_catalog

Dev tooling: one page showing every state of every widget and screen at once, light and dark side by side, with live theme tokens.

How to write `samples()` and entries: [`docs/boundaries.md`](../../docs/boundaries.md) section 7.

```dart
CatalogPage(
  entries: [
    CatalogEntry(name: 'Button', kind: CatalogKind.widget, states: {
      'enabled': (context) => const MyButton(),
    }),
    // One state per named sample, built from plain data:
    CatalogEntry.fromSamples<String>(
      name: 'Label',
      kind: CatalogKind.widget,
      samples: {'short': 'hi', 'long': 'a much longer text'},
      build: (s) => Text(s),
    ),
  ],
  themeBuilder: (tokens, brightness) => myTheme(tokens, brightness),
  fontFamilies: ['Roboto', 'Inter'],
  paletteColors: {'primary': Colors.indigo},
)
```

## Entries

- `CatalogEntry(name, kind, states)` takes one builder per state label.
- `CatalogEntry.fromSamples<T>(...)` makes one state per entry in `samples`, each built from that sample; the sample key is the state label.
- Widgets are listed first, screens below. Screens render in fixed 390x844 frames scaled to 0.4 (320 wide when Narrow is on).

## Display toggles

Three switches apply to every tile, light and dark alike:

- **Large text (2x)** sets the text scaler to 2.0 (otherwise it follows `fontScale`).
- **Narrow (320)** limits widget tiles to 320 logical pixels and reports 320 as the tile's `MediaQuery` width.
- **Right-to-left** wraps each tile in `Directionality(rtl)`.

## Tokens

The side panel edits `CatalogTokens`, and every tile rebuilds with `themeBuilder(tokens, brightness)`. The catalog only edits these values; the app's `themeBuilder` decides what they mean by mapping them onto its real design tokens:

- `seed`: seed colour (four preset swatches).
- `fontFamily`: picked from `fontFamilies`.
- `fontScale` (0.8-1.4): text scale. Overridden by Large text.
- `spacingScale` (0.75-1.5): spacing. The catalog's own tile gaps stay fixed.
- `sizeScale` (0.75-1.5): sizing.
- `colorOverrides`: palette key -> chosen colour, set from `paletteColors`.

## Palette

`paletteColors` maps palette keys to their current colours. When it is non-empty, the side panel shows one row of four preset swatches per key instead of the seed-colour row. Tapping a swatch sets `colorOverrides[key]`, and the selected swatch shows the current override, or the palette colour if none is set.

A builder that throws shows an error tile; the page keeps working.
