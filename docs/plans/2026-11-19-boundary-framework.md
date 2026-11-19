# Boundary framework: where the backend may be touched (plan, rev 4)

Goals: `docs/ui-framework-goals.md` (numbers below refer to it). Tested first by `2026-11-19-boundary-spike.md`; anything the spike shows to be wrong changes here before phase 1.

Rev 4 (review fixes): cubits are created from scope factories, never `GetIt` in widgets; lists use one `Connect` per item so one change rebuilds one item; per-instance state rule made explicit; composition-root exemption narrowed to functions; view bans widened (types by declaring path, casts, `BuildContext` extensions); `Connect` selectors must be static; adapters expose a pure `assemble` shared with the catalog; catalog gains light/dark and font family.

Rev 3 changes: regions dropped (coarse rebuilds hurt goal 11; finished children serve goal 7 without them); the adapter is split into two one-way streets; scopes are only for state that outlives its UI; `AppScreen`/`ScreenRoute` moved to a later phase (goal 6 is nice to have).

## Problem

Flutter, bloc and GetIt let any widget, at any depth, reach any cubit or service (`context.read`, `BlocBuilder`, `GetIt.I`, or a cubit held as a field). Each lookup is invisible in the constructor. Apps drift into pure leaves, a middle layer that fetches its own state, and screens that need everything below them. Stories then need large fake backends that fail one missing fake at a time, the gallery cannot show screens, and long-lived state piles into whichever widget is high enough (Episutra's shell provides ~15 cubits so they outlive a notebook switch). Conventions exist but nothing enforces them.

## The pattern

Today's ideal form is cubit > adapter > view. Three changes, plus enforcement:

**1. The adapter becomes two one-way streets.**

```
down:  select : State -> ViewData           a pure function, unit-tested without widgets
up:    XActions : interface the cubit implements (one method per user intent)
glue:  Connect(select, builder: (data, actions) -> view)   framework widget, written once
```

`Connect` resolves the cubit, runs `select`, rebuilds its builder only when the selected `ViewData` changes (value equality, `@freezed`), and passes the cubit as `XActions`. `select` must be a static or top-level function (as `cubitField` already requires), since the listenable is cached by selector identity. `XActions` method names must not collide with `BlocBase`'s API (`close`, `emit`, `onChange`, `onError`, `addError`, `state`, `stream`, `isClosed`); a lint checks it.

**Assembly is written once.** Each adapter exposes a static pure `assemble(ViewData, XActions, children) -> Widget`. Its `Connect` builder calls it with real data; the catalog calls the same function with fakes, so the catalog cannot drift from the app (goal 4).

**Lists rebuild per item.** A list adapter selects only the ids; the list view takes an `itemBuilder(id)`, and the adapter passes `(id) => NoteTileAdapter(id)`, each with its own `Connect` selecting one item. Changing one note rebuilds one tile. `Connect2` does the same over two cubits (`select: (S1, S2) -> ViewData`). An adapter is a small widget class whose build is a `Connect`. When an action needs UI (confirm dialog, navigation, toast), the adapter wraps the cubit in a UI-side `XActions` implementation; cubits never open dialogs.

**2. Lifetime: on the tree by default, a scope only when lifetime differs from position.**

- Local state whose life matches a piece of UI (a dialog form, a settings section): the adapter provides the cubit with `BlocProvider`, created from a factory on a scope (`ScopeProvider.of<SessionScope>(context).newRenameForm()`), never from `GetIt`. It is disposed with that UI.
- Per-instance state (one cubit per tab): on the tree if its life matches the instance's widget; in a scope keyed by instance id if it must survive the widget going away (a tab switched out of view).
- State that must outlive the UI around it (survives a notebook switch, spans a multi-route flow, is shared by distant regions): an `AppScope` owns it. A scope is a plain object with `dispose()`, placed on the tree by a `ScopeProvider` at the node whose life it shares (app root for the session, a `ShellRoute` for a flow, the workspace node for per-notebook state). `Connect` takes an optional `resolve: (context) -> cubit` to read from a scope. `ScopeProvider` is a stateful widget that creates its scope once (from a `create` callback) and disposes it; it must not construct the scope inside a builder closure, or every navigation would recreate it.

**3. Containers take finished children, not their children's arguments.**

```
before:  Tile(title, tag, onTagTap)     Tile builds Chip inside and passes arguments through
after:   Tile(title, trailing)          caller passes the finished Chip:  trailing: Chip(tag, onTap)
```

Arguments come in three kinds, told apart by type: data (values, `ViewData`), callbacks (`on...`, the up street), and finished children (`Widget`, or `Widget Function(...)` for lists). Leaves take data and callbacks. Containers take data for what they draw themselves and finished children for everything else. The adapter assembles the pieces; the catalog assembles them from fakes. A view may fill a child position itself only with something needing no data or actions (a fixed icon). The tell that something should be a finished child: an argument the widget only hands on.

**Enforcement and payoff.** Lints keep the backend out of views (goal 8); the catalog shows everything (goals 1-4).

**Performance (goal 11).** `Connect` rebuilds only on a changed `ViewData`; adapters stay small, because an adapter rebuild rebuilds what it assembled. High-frequency data (typing, pointer, streaming) travels through controllers or narrow listenables handed down by the adapter, never through `ViewData`. Checked with `BuildCounter` tests.

**Ambient context** (allowed in views): `Theme`, `MediaQuery`, `Directionality`, `Localizations` and l10n accessors, `DefaultTextStyle`, `FocusScope`, `Shortcuts` (views dispatch `Intent`s; adapters provide the `Action`s that do backend work). Data and services are never ambient.

## Roles and what the lints allow

| Role | Is | May | May not |
|---|---|---|---|
| View | any `Widget` that is not an adapter, plus `BuildContext` extensions and top-level functions returning `Widget` | data, callbacks, finished children, controllers/listenables passed in; ambient context; local UI state | `context.read/watch/select`, `Provider.of`, bloc widgets, `UiFlowListener`, `ScopeProvider.of`, `Connect`, `GetIt`; fields, parameters or casts of a `BlocBase` subtype, an `AppScope` subtype, or any type declared under the app's data paths (`lint_config.yaml`, default `lib/data/`, `lib/infrastructure/`) |
| Adapter | subclass of `AdapterWidget` (new, stateless or stateful) or of `CubitAdapter`/`MultiCubitAdapter` (existing), named `*Adapter` | `Connect`, bloc providers and APIs, `ScopeProvider.of` (including scope factories for local cubits), `UiFlowListener`; own controllers; open dialogs, navigate | `GetIt` |
| Scope | subclass of `AppScope` (plain class) | own long-lived cubits; expose factories for local cubits; `GetIt` | be a widget |
| Composition root | top-level functions and route closures in files listed in `lint_config.yaml` (bootstrap, router); widget classes in those files are ordinary views or adapters | `GetIt`; build scopes; fill top-level children with adapters | |

## Packages

1. **`cubit_ui_flow`** (changed): `Connect`, `Connect2`, `AdapterWidget`, `AppScope`, `ScopeProvider`; the `resolve` hook on `CubitAdapter`/`MultiCubitAdapter` (default stays `context.read<C>()`).
2. **`systematic_lints`** (changed; supertype matching by name; rules apply to `Widget` subclasses and their `State`s only, so cubits, services and scopes are untouched):
   - `backend_access_only_in_adapters`: the view "may not" column. `GetIt` banned in all widgets. Opted-in apps disable `avoid_bloc_imports_in_widgets_dir`; `avoid_getit_in_adapters_dir` is subsumed. Old rules stay for apps not opted in.
   - `adapter_naming`: adapter classes end in `Adapter`, and no other `Widget` subclass does (non-widget classes such as a palette adapter are untouched).
   - `actions_avoid_bloc_names`: `*Actions` interfaces declare no member named like `BlocBase` API.
   - `require_static_selector` and `cubit_field_selector_must_be_equatable` extended to `Connect`/`Connect2`.
   Not enforced: `*View` naming (primitives and small widgets are views without the suffix; deliberate).
   Each with analyzer tests per banned form. Apps add new diagnostic names to `analysis_options.yaml` `diagnostics:` and their ratchet script's pattern.
3. **`systematic_catalog`** (new; dev tooling): entries (name, explicit kind widget or screen, map of state name to builder; entries usually call an adapter's `assemble` with fakes); widgets on top, screens below, every state visible in light and dark side by side; side panel for colour, font family, font scale and spacing scale through the theme; an adapter from Widgetbook's generated `directories` where the kind comes from an explicit marker in the story (until `AppScreen` lands and the type decides).
4. **`systematic_ui/testing`**: `BuildCounter`.
5. **Docs:** `docs/boundaries.md` (the pattern in plain words, roles, the three argument kinds, ambient list, performance rule, adoption order).

## Adoption in an app (Episutra first)

1. Pins to https at the current ref, including the lints plugin entries in both `analysis_options.yaml` files; `check_systematic_pins.sh` requires one URL. Independent; can land now.
2. Bump; enable the new rules; baseline existing findings (Episutra's baseline is empty and the old folder rules were never enabled, so every finding is new; the ratchet only blocks growth).
3. Migrate: onboarding (a `ShellRoute` flow scope replaces `state.extra`; test that state carries across steps), settings (including the settings window that re-provides cubits), then the shell last: scopes for notebook-level state with notebook-switch tests first, per-tab state, keybindings via `Intent`/`Action` (replacing GetIt lookups in `global_keybinding_scope.dart` and `editor_tab_strip.dart`), then pieces one by one with `BuildCounter` checks on typing, graph panning and chat streaming.
4. Catalog swap via the Widgetbook adapter.

Episutra-specific findings in `2026-11-19-screens-and-catalog.md` (renames, `_TaskNodeModalScreen`, pins, `check_lints.sh` pattern, AGENTS.md lines) apply.

## Phases

0. Spike; revise this plan from its write-up.
1. Framework v1: packages 1-5; tests green; pushed with a sha.
2. Episutra adoption steps 1-4, each a separate branch and review.
3. Catalog absorbs `flutter_widgetsystem` (`StatesGrid`, palette editor); Episutra drops it, its last path dependency, and `sibling-versions.lock`.
4. Nice to have: `AppScreen` and `ScreenRoute` (`systematic_screen`), screen lints, catalog classification by type.
5. Other apps opt in when they next bump.

## Open decisions

1. Cross-cubit coordination with no UI (Episutra's `graph_coordination_adapter`): an adapter with no view, or a scope-level coordinator. Decide in phase 2.
2. Dialogs: an `AppDialog` type, or adapter-opened views as now. Deferred.
3. If a deep non-list tree makes finished children awkward, revisit a context-based option then, with the real case in hand.

## Breaking changes

Apps pin refs, so nothing breaks until they bump; apps not opted in keep the old rules.
