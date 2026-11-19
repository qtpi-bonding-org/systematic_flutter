# systematic_catalog

Dev tooling: one page showing every state of every widget and screen at once, light and dark side by side, with live theme tokens.

```dart
CatalogPage(
  entries: [
    CatalogEntry(name: 'Button', kind: CatalogKind.widget, states: {
      'enabled': (context) => const MyButton(),
    }),
  ],
  themeBuilder: (tokens, brightness) => myTheme(tokens.seed, brightness),
  fontFamilies: ['Roboto', 'Inter'],
)
```

- Widgets are listed first, screens below (fixed 390x844 frames scaled to 0.4).
- The side panel edits `CatalogTokens` (seed colour, font family, font scale 0.8-1.4, spacing scale 0.75-1.5); every tile rebuilds with `themeBuilder(tokens, brightness)`.
- A builder that throws shows an error tile; the page keeps working.
