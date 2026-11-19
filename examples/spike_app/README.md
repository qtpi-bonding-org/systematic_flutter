# spike_app

A small notes app that serves as a reference example of the cubit > adapter > view pattern, built on the systematic_flutter packages (cubit_ui_flow for scopes and Connect, systematic_catalog for the component catalog).

- `lib/*/` cubits hold state and expose actions; `lib/adapters/` connects cubits to views; `lib/views/` is presentation only.
- Tests: `flutter test` (rebuild counts, selectors, state flows).
- Analyze: `dart analyze` (the systematic_lints plugin runs there, not in `flutter analyze`).
- Catalog: `flutter run -t lib/catalog_main.dart -d macos` shows every view in each state with no scopes or cubits.
