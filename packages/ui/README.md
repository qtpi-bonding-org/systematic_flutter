# systematic_ui

Shared Flutter design system bones for the apps (episutra, quanitya, and future apps).

This is the single source of truth for tokens (`AppSizes`, `VSpace`, `HSpace`, `AppPadding`, `UiScaler`), the theming mechanism (`ThemeService`) and the structural primitives (`DsColumn`, `DsRow`, `DsGroup`). App-specific brand (palette values, fonts) and signature widgets stay in each app.

The hand-rolled Storybook that used to live here was removed (no app imported it); widget catalogs are built with Widgetbook via `flutter_widgetsystem`.

See `docs/specs/` for the original design docs (they still describe the storybook that was removed).
