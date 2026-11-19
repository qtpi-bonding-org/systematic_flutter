> **Superseded** by `2026-11-19-boundary-spike.md`. Kept for the review findings, which still apply to the Episutra adoption.

# Screens as a type, and a catalog that shows everything (plan, rev 2 after Opus review)

## What the review changed (rev 2)

- **Catalog classifies by component name, not by building.** Every screen story wraps the screen in a provider or host, so `built widget is AppScreen` would find none. The generated tree already carries the component name (`@UseCase(type: X)`), and the naming rules make "ends in `Screen`" equal "extends `AppScreen`".
- **`ScreenRoute` takes a `wrap` hook.** Today's route builders return `BlocProvider(child: WelcomePage())` and pick `BlocProvider.value` from `state.extra`; a builder that must return an `AppScreen` would reject them. Providers go in `wrap`, or the screen builds its own with the `extra` cubit as a constructor argument.
- **The lint also closes the private-class loophole.** Pages hand their build to a private class in the same file, which the rule never visits (the baseline has zero findings for it today). New check: any other `Widget` subclass declared in a file that declares an `AppScreen` is flagged.
- **Rename list corrected** (see Steps). `TaskLaneView` already exists; `TaskLanePage` and `relevance_section.dart` import bloc/get_it, so they are adapters, not views. `_TaskNodeModalScreen` would trip the naming rule.
- **`flutter_widgetsystem` is used by 43 story files** (`ws.StatesGrid` 40 times, `ws.PaletteScope`), so the catalog keeps `StatesGrid` and the adoption rewrites those imports.
- **Step 6 split in three**, and the missed pin and lint-script spots added.
- **Cut:** the empty Dialogs section and the compile-fail fixture test.

## Goal

1. A **screen is a type**, not a naming habit. Routing accepts only screens, a screen is built from widgets, and tooling can tell screens from widgets by type.
2. A **catalog** (replacing `flutter_widgetsystem`) shows every widget, dialog and screen of an app on one scrollable page, with live token (colour, font) editing. An agent edits Dart, hot reload updates the page.
3. Episutra adopts both, which also removes its last relative-path dependency (`flutter_widgetsystem`).

## Facts checked (2026-11-19)

- `packages/lints` already has `no_inline_widget_composition_in_pages`. It finds pages **by class-name suffix** (`page_suffix`, default `Screen`; Episutra's `lint_config.yaml` overrides it to `Page`) and skips files under `widgets/` or `adapters/` directories. It bans layout widgets (`Padding`, `Column`, `Row`, `Container`, `SizedBox`, `Text`, `Scaffold`, ...) constructed inline in a page's `build()`. It has a test file using analyzer stubs.
- `packages/ui` (`systematic_ui`) has no `go_router` dependency. `packages/nav_snapshot` does (`go_router >=13 <18`) but is about startup routing state, and Episutra does not use it.
- Episutra routes with raw `GoRoute` in `app_router.dart`. Real routed things: `WelcomePage`, `SetupPage`, `RecoveryKeyBackupPage`, `HomeShell` (wraps `ShellPage`), plus `BootstrapLoadingScreen` shown before the router exists. `TaskLanePage` is never routed (embedded in the editor tab rail); `settings/pages/relevance_section.dart` is a settings section, not a page. About ten dialogs use `showDialog`.
- Episutra has 52 story files and 57 use cases. Views are prop-driven (e.g. `AppearanceSectionView(themeMode, onChanged)`); adapters connect cubits. `ShellPage` needs ~15 fake cubits plus GetIt registrations.
- Widgetbook's generated `directories` is a nested tree of `WidgetbookFolder` / `WidgetbookComponent` / `WidgetbookUseCase(name, builder: Widget Function(BuildContext))`. A catalog can walk it, so the 57 stories are reused unchanged.
- `flutter_widgetsystem` (13 lib files, ~730 lines, no remote, left out of the consolidation as dev tooling) wraps `Widgetbook.material` with: `ThemeService` + `IColorPalette` (live tokens), `PaletteAddon`/`PaletteEditor`, `ScalerAddon`/`UiScaler`, `StatesGrid`, contrast utilities. Episutra uses only `WidgetSystem`, `BuilderAddon`, `ThemeService`, `IColorPalette`, from two files.
- Episutra pins `systematic_flutter` with `git@github.com:...` SSH URLs at `079aa2b` (eight places in `app/episutra_flutter/pubspec.yaml`, more in `packages/episutra_core/pubspec.yaml`). The repo is public, so plain https works anonymously.

## Design

**Vocabulary (one name per kind):** `*Screen` (routed, complete), `*Adapter` (state to view), `*View` (pure view), `Episutra*`/app prefix (primitive), `*Dialog`. Widgets get no `Widget` suffix.

**`AppScreen`** (new package `packages/screen`, pub name `systematic_screen`): an abstract `StatelessWidget`. A screen composes already-built widgets. Stateful needs move into a child widget. Open question: carry anything beyond the type (a test id, a standard scaffold)? Default answer: no, start with the type only.

**`ScreenRoute`** (same package, depends on `go_router`): a `GoRoute` subclass (`GoRoute` is not final in go_router 17.2.3) whose `screen` builder returns `AppScreen`, with an optional `wrap: (context, state, child)` for providers. It hides `builder`/`pageBuilder`, so a non-screen cannot be routed and the type signature is the test. The router's `errorBuilder` is not a route; it should become an `AppScreen` too (`RouteErrorScreen`) so nothing in the router builds layout inline. It lives in its own package, not `ui` (no go_router there) and not `nav_snapshot` (different concern, would add a dependency to apps that do not use it).

**Lint** (`packages/lints`): replace suffix matching with type matching. A class is a screen if any supertype is named `AppScreen` (matched by name, so `lints` still has no dependency on other packages). Rules: (a) an `AppScreen` subclass must end in `Screen`; (b) a class ending in `Screen` must extend `AppScreen`; (c) the existing "compose, don't build layout inline" check applies to `AppScreen` subclasses; (d) any other `Widget` subclass declared in a file that declares an `AppScreen` is flagged (closes the private-class loophole). Supertype-by-name matching has precedent in `exceptions_extend_failure_base.dart` and `failure_helpers.dart`. `page_suffix` and the `widgets/adapters` directory skip are removed. If the new rules get their own diagnostic names, add them to the `LINT_LINE` regex in Episutra's `scripts/check_lints.sh` and to the `diagnostics:` list in both `analysis_options.yaml` files, or they are silently ignored. Breaking change; apps pin refs.

**Dialogs:** same pattern later (`AppDialog`, `showAppDialog` accepting only it). Out of scope here.

**Catalog** (new package `packages/catalog`, pub name `systematic_catalog`, dev tooling): builds on Widgetbook's generated `directories`. Walks the tree and classifies each `WidgetbookComponent` by its name: ends in `Screen` goes to Screens; the rest to Widgets (a Dialogs section is added when `AppDialog` exists). Use-case builders are plain `WidgetBuilder`s (widgetbook 3.25.0), called inside the catalog's own `Builder` at layout time, so no building is needed to classify. Layout: Widgets as a dense wrap of labelled tiles; Screens as larger fixed-size frames; heavy stories (PDF, graph canvas, image) built lazily when scrolled into view. A side panel holds the token editor (palette, fonts) and viewport/scale controls, ported from `flutter_widgetsystem` (`ThemeService`, `IColorPalette`, `PaletteEditor`, `UiScaler`). Widgetbook's own one-at-a-time UI stays available as a second entry point.

## Steps

Each step is a separate commit; each package passes `flutter pub get`, analyze and tests from its own folder.

1. **Branch** `screens-and-catalog` in `~/Documents/systematic_flutter` off `main`.
2. **`systematic_screen`**: `AppScreen`, `ScreenRoute` (with `wrap`), tests (a routed screen builds, `wrap` receives the screen, `extra` reaches the builder).
3. **Lint**: type-based rule, naming rules, private-class rule; update the existing test file (subclass-by-type, wrong suffix, `Screen` not extending `AppScreen`, a screen inside a `widgets/` folder, a private helper widget in a screen's file).
4. **Catalog package**: port `flutter_widgetsystem` pieces including `StatesGrid`, `PaletteScope`, `ThemeService`, `PaletteEditor`, `UiScaler`; add the directory walker, name classifier, gallery page, token panel. Tests: walker and classifier on a fake tree; a widget test that renders the two sections.
5. **Push the branch**, note the sha. (Orchestrator pushes; no force.)
6. **Episutra adoption in three separate commits** (branch off `feat/git-pins`, after step 5):
   - **6a. Pins to https.** At the current `079aa2b`, normalise every `git@github.com:qtpi-bonding-org/systematic_flutter.git` to the https URL in `app/episutra_flutter/pubspec.yaml`, `packages/episutra_core/pubspec.yaml` and the lints plugin entries in both `analysis_options.yaml` files (`app/episutra_flutter/analysis_options.yaml` ~56-60, `packages/episutra_core/analysis_options.yaml` ~55). Extend `scripts/check_systematic_pins.sh` to require one https URL (it compares refs only today). Can land now.
   - **6b. Screens and lint.** Bump the pin; add `systematic_screen`. Renames: `WelcomePage`/`SetupPage`/`RecoveryKeyBackupPage` to `*Screen`; `HomeShell` to `HomeScreen` (update `test/app_router_home_shell_test.dart`); `BootstrapLoadingScreen` extends `AppScreen`; router `errorBuilder` becomes `RouteErrorScreen`; `SetupScreen` keeps its timer/`initState` in a child widget; `features/*/pages` to `features/*/screens`; private `_TaskNodeModalScreen` renamed `_TaskNodeModalBody`. `TaskLanePage` (not routed, uses bloc/get_it) becomes `TaskLaneAdapter` in `adapters/` (a `TaskLaneView` already exists); `settings/pages/relevance_section.dart` moves to `adapters/` (same reason; `scripts/check_adapter_boundary.sh` rule 1 forbids bloc/get_it in `widgets/`). `ShellPage` stays a widget inside `HomeScreen` but needs a role name that is not `Page` or `View` (a `*View` story with fakes is rejected by `test/enforcement/widgetbook_view_story_boundary_test.dart:19-29`); decide the name in this step. `app_router.dart`: `GoRoute` to `ScreenRoute` with `wrap` for the `BlocProvider`/`extra` logic; add an enforcement test banning raw `GoRoute(` in the router file. Update `lint_config.yaml` (drop `page_suffix`), refresh `scripts/lint_baseline.txt` with `check_lints.sh --update` and say so in the commit. Update `AGENTS.md` (vocabulary, folder rule; lines ~222, 505, 512 mention the lock and `flutter_widgetsystem`).
   - **6c. Catalog swap.** Add `systematic_catalog`, remove `flutter_widgetsystem`, rewrite the 43 story imports (`ws.StatesGrid` x40, `ws.PaletteScope`), replace `widgetsystem_main.dart` with a catalog entry point. Delete the `flutter_widgetsystem` lock entry; if nothing path-based remains, delete `sibling-versions.lock`, `scripts/check_sibling_versions.sh` and its `check_all.sh` step (this also drops the `ag_ui_widgets_flutter` ref check, which is fine since the pubspec pins it).
   - Verify after each: `dart analyze` on both packages, `flutter_test_native.sh` for affected tests, `scripts/check_all.sh --fast`.
7. **Sibling lock**: removed in 6c as above.

## Risks and open questions

- **Stateful screens.** `SetupPage` is stateful; the abstract stateless base forces a refactor. Alternative: make `AppScreen` an abstract class that both `StatelessWidget` and `StatefulWidget` subclasses can satisfy via a marker mixin. Decide in step 2; the stateless base is cleaner for the lint.
- **Classification by component name** relies on every screen story using `@UseCase(type: <Screen>)`. The naming lint guarantees `Screen` suffix means `AppScreen`; a test in the catalog package can assert each `*Screen` component's type is an `AppScreen` if the type is reachable.
- **Cost of screens in a gallery.** The shell needs the full fake-cubit graph; several screen states multiply that. Lazy building and one shared wiring per screen.
- **Hot reload scope.** Works in debug runs of the catalog entry point only; assumed acceptable (dev tool).
- **Lint breaking change.** Other apps (Quanitya, Pocketcoder, Achaean, archescope) pin by ref, so they are unaffected until they bump; they use `page_suffix` configs that will need updating then.
- **Repo remote name.** `origin` push URL still uses the old `qtpi_flutter_system.git` name (it works via redirect). Pins use the new name.
- **Mobile.** `AppScreen`/`ScreenRoute` are portable (go_router 17.2.3 in Episutra, package range >=13 <18); the catalog is dev-only and desktop/web.
- **Widgetbook version coupling.** The catalog depends on the generated node types; a Widgetbook major bump may change them.

## Out of scope

`AppDialog`; renaming widgets that do not lie about their role; any change to Quanitya/Pocketcoder/Achaean/archescope; moving the catalog into the apps.

## Done when

`systematic_screen`, the lint change and `systematic_catalog` pass analyze and tests in `systematic_flutter` and are pushed; Episutra builds, analyzes and passes its fast checks on the new pins; no `GoRoute(` outside `ScreenRoute` in `app_router.dart`; every routed class extends `AppScreen` and ends in `Screen`; the catalog shows Widgets and Screens sections with the token panel; `flutter_widgetsystem` is no longer a dependency of Episutra.
