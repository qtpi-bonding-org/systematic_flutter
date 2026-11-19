# Boundary spike: a tiny notes app (plan, rev 4)

Tests `2026-11-19-boundary-framework.md` (rev 3) at toy size. Goals: `docs/ui-framework-goals.md`. Supersedes `2026-11-19-screens-and-catalog.md`.

## The app

`examples/spike_app/` in this repo, depending on the packages by path. Not published, nothing depends on it.

Tree:

```
HomeView(tabs:, search:)                        finished children, filled by the route
  TabStripView(tabs, active, onSelect)          two note tabs
    NotesAdapter(tabId)   Connect(selectNoteIds), cubit from WorkspaceScope keyed by tabId
      NoteListView(ids, itemBuilder)            itemBuilder: (id) => NoteTileAdapter(tabId, id)
        NoteTileAdapter(tabId, id)  Connect(selectNote(id))   one Connect per item
          NoteTile(title, trailing, onDelete)
            TagChip(label, onTap)               leaf
  SearchAdapter           Connect2(search cubit, session status cubit)
    SearchPanelView(data, controller, onQuery)
```

## Hard cases, each exactly once (12)

| # | Hard case | Where |
|---|---|---|
| 1 | Deep tree, no pass-through arguments, two streets | `NoteListView` takes an item builder; `NoteTile` takes a finished chip; adapters assemble via `assemble`; `select` functions are pure; `NotesCubit implements NotesActions` and views see only `NotesActions` |
| 2 | One change rebuilds one item | renaming one note rebuilds only that tile (per-item `Connect`) |
| 3 | Two cubits into one view | `SearchAdapter` uses `Connect2` |
| 4 | Local cubit on the tree, in a dialog | "Rename note" dialog: its adapter provides its own form cubit, created from a `SessionScope` factory (no `GetIt`); closed when the dialog closes |
| 5 | State that outlives its UI | switching workspace A/B replaces the workspace scope (new notes cubits); the search query lives in the session scope and survives |
| 6 | Per-instance state that outlives its widget | two note tabs, each with its own notes cubit kept in `WorkspaceScope` by tab id; switching tabs keeps each tab's state |
| 7 | Flow across routes | `/start` > `/start/confirm` share one cubit through a `ShellRoute` that provides a flow scope; no `state.extra` |
| 8 | Hot path through a controller | the search field's `TextEditingController`, owned by `SearchAdapter`, handed down; typing never goes through `ViewData` |
| 9 | Hot path through a listenable | a ticking status stream shown by one small view |
| 10 | Action that needs UI | delete asks for confirmation: `NotesAdapter` wraps the cubit in a UI-side `NotesActions` that shows the dialog, then calls the cubit |
| 11 | Keybinding doing backend work | Ctrl+Backspace deletes the selected note: a view dispatches an `Intent`, `NotesAdapter` provides the `Action` |
| 12 | Everything in the catalog with no backend | every view and `HomeView` shown through the adapters' `assemble` functions with literal `ViewData`, no-op actions and fake children, in light and dark |

Not tested (the write-up must not claim them): cross-cubit coordination with no UI, toasts through `UiFlowListener` and mappers, the Widgetbook adapter, coexistence with the old lint rules, `AppScreen`/`ScreenRoute`, localisation.

## Framework pieces built for it (minimal)

1. `cubit_ui_flow`: `Connect`, `Connect2`, `AdapterWidget`, `AppScope`, `ScopeProvider` (stateful, creates the scope once), `resolve` hook.
2. `systematic_lints`: `backend_access_only_in_adapters` (including casts, data-path types, `BuildContext` extensions, composition-root functions only), `adapter_naming` (widgets only), `actions_avoid_bloc_names`, static-selector rules extended to `Connect`, with analyzer tests (one violating and one clean case per banned form).
3. `systematic_catalog`: entries list with explicit kind, widgets on top and screens below, all states in light and dark, side panel (one colour, font family, font scale, spacing scale). No Widgetbook.
4. `systematic_ui/testing`: `BuildCounter` (a wrapper counting its own builds).

## Success criteria

1. Every view and `HomeView` render in the catalog with zero cubits, zero scopes and zero `GetIt`.
2. Each lint rule flags each banned form in its tests; the spike app analyzes clean with the rules on.
3. `select` functions are covered by plain unit tests.
4. Rebuild tests (`BuildCounter` around the spike's own widgets; fake time for the ticker): typing rebuilds only the counted search-field wrapper; a tick rebuilds only the status view; renaming one note rebuilds only that tile; deleting a note rebuilds the list and not the search panel.
5. State tests: a workspace switch keeps the search query; both flow steps see the same cubit instance; two tabs have independent lists and keep them across a tab switch; the rename dialog's cubit is closed when the dialog closes.
6. Change cost: for three sample changes, made on a scratch copy and then reverted — (a) show the note's created date on NoteTile, (b) add a 'pin note' button that calls a new cubit method, (c) restyle TagChip — record files read and files edited, and whether any widget gained an argument it only passes on. Target: each change edits at most 2-3 files (cubit/select/actions, the view, the adapter's assemble) and no pass-through arguments.

## Steps

Branch `boundary-spike` off `main` in this repo. One commit per step; each package passes `flutter pub get`, analyze and tests from its own folder.

1. `cubit_ui_flow` additions with tests.
2. Lint rules with tests.
3. `systematic_catalog` (minimal) and `BuildCounter`.
4. Spike app with its unit, state and rebuild tests and a catalog entry point.
5. Write-up appended here: what held, what felt heavy, what changes in the framework plan.

Not pushed until gp has read it.

## Out of scope

Episutra changes; Widgetbook; localisation; mobile; `AppScreen`/`ScreenRoute`; `AppDialog`; Riverpod.

## Spike write-up

Built on branch `spike-app`: ConnectFor and two lint fixes (step 1), `examples/spike_app` (step 2). Spike app: 1762 lines of lib (cubits and scopes 421, views 415, adapters 468, app.dart 86, catalog 359), 25 tests, `dart analyze` clean with the plugin confirmed active. Process note: tests were written first; what I watched fail was the compile failure (no `lib/` yet), not each test individually. Production code was written by Haiku, reviewed and run by me.

### Success criteria

1. **Held.** `catalog_test.dart`: "catalog lists every view with the right kind" (12 entries: 9 widgets, HomeView, StartView, ConfirmView as screens) and "catalog page renders every entry with no scopes or cubits" (no `ScopeProvider` or `BlocProvider` in the tree; GetIt is not a dependency). Every entry is built through an adapter's `assemble` with literal data and no-op actions.
2. **Held, with one trap.** `packages/lints`: 160 analyzer tests, one violating and one clean case per banned form, including the two fixes made here (`ConnectFor` selectors and bans in views; implicit-this `read/watch/select` inside a `BuildContext` extension). The spike analyzes clean. Confirmed active by a probe file (view with `context.read`, an extension with implicit `read`, a non-adapter class named `*Adapter`): all three reported, then the probe removed and the result clean. The trap: the first clean result was false. The plugin loaded but reported nothing until each rule was listed under `plugins: systematic_lints: diagnostics:` in `analysis_options.yaml` (lint rules are off by default), and `tool/smoke.sh` fails for the same reason. The README does not say this.
3. **Held.** `select_test.dart` (6 tests): ids ignore other fields, one note selected by id, an untouched note's data is equal after another changes, search panel ignores ticks, tick, rename form validity.
4. **Held, with a seam.** `rebuild_test.dart`: "typing rebuilds nothing after the first character" (stricter than the plan: the panel rebuilds once when the query goes from empty to non-empty, then never), "one status tick rebuilds only the status view", "renaming one note rebuilds only that tile", "deleting a note rebuilds the list but not the search panel", plus selecting a note rebuilds only the affected tile. `BuildCounter` cannot observe production widgets from outside, so the adapters' `assemble` functions wrap their view in a `probe(id, child)` hook (a mutable top-level function in `lib/probe.dart`, a no-op by default; tests install `BuildCounter`). This is test code in production files.
5. **Held.** `state_test.dart`: "workspace switch keeps the search query, replaces notes cubits" (old cubits closed), "two tabs are independent and kept across a tab switch", "both flow steps see the same cubit instance", "flow scope is disposed when the flow is left", "rename dialog cubit is closed when the dialog closes", plus delete confirmation, Ctrl+Backspace (with and without a selection) and the search text surviving a panel rebuild.
6. **Change cost (measured by making each change on the working tree and reading the analyzer output, then reverting with `git checkout lib`).**
   - (a) Created date on NoteTile: files edited 3 core (`notes_cubit.dart`: `Note`, `NoteTileData`, `selectNote`; `views/note_tile.dart`; `adapters/note_tile_adapter.dart`: `assemble`) plus 2 forced by the compiler when the new field is required: `catalog_main.dart` (3 literal `NoteTileData` sites) and `test/select_test.dart` (1). Files read: the same 5, found by analyzer errors. Pass-through arguments: none (`NoteTile` draws `created` itself; the adapter's builder is untouched because `assemble` takes the whole `NoteTileData`). Target met for production code (3); 5 files if catalog and test count.
   - (b) Pin button calling a new cubit method: 5 files edited: `notes_cubit.dart` (interface `NotesActions.pin`, `NotesCubit.pin`, state and select if the pin shows), `adapters/ui_notes_actions.dart` (forwarding method, compiler-forced), `catalog_main.dart` (the no-op `NotesActions` fake, compiler-forced), `views/note_tile.dart` (button and `onPin`), `adapters/note_tile_adapter.dart` (`assemble` passes `actions.pin`). Pass-through: none. Target missed: 5 files vs 2-3, because every `NotesActions` implementer must change.
   - (c) Restyle TagChip: 1 file read, 1 edited (`views/tag_chip.dart`), nothing else compiles differently. Target met.
   No widget gained an argument it only passes on in any of the three.

### What felt heavy

- Lines of glue: a feature costs a cubit, a state, one or two ViewData classes with hand-written `==`/`hashCode`, an actions interface, an adapter (25 to 75 lines, mostly Connect type arguments and the `assemble` signature), a view, and a catalog entry. The notes feature alone is about 190 lines of cubit and data plus 280 of adapters (notes, tile, UI actions, rename dialog). The hand-written value classes are the biggest single cost; freezed was left out of the spike on purpose, and Episutra has it.
- `Connect` type arguments are long (`Connect2<SearchCubit, SearchState, StatusCubit, StatusState, SearchPanelData>`); they cannot be inferred because `select` is a tear-off.
- Wrapping a cubit in a UI-side `NotesActions` (hard case 10) means a full forwarding class (`UiNotesActions`) for one method that needs UI. Every new action touches it.
- The catalog file is the largest single file (359 lines): no-op fakes for five actions interfaces and literal data at every call site, so a new ViewData field breaks several catalog sites.
- Places the pattern fought back: `ScopeProvider.of` in `initState` or in a `BlocProvider.create` throws, so `SearchAdapter` creates its controller lazily in `build` and `RenameDialogAdapter` reads the scope in `build` and captures it; the workspace switch needs a keyed `ScopeProvider` inside its own `WorkspaceHostAdapter`; a Connect that depends on an id must be keyed (`ValueKey(id)`), and forgetting that silently shows the old cubit (the tab switch relies on it).
- `UiNotesActions` holds a `BuildContext` in a plain class; no rule flags it.

### What should change in the framework plan before phase 1

1. Add `ConnectFor` (selector with an argument) to the framework package list; `Connect` alone cannot do per-item rebuilds with a static selector. Built here.
2. Document that rules must be listed under `diagnostics:` in `analysis_options.yaml`, and make `tool/smoke.sh` take that into account; otherwise a clean result is meaningless.
3. Offer a way to build UI-side actions wrappers without forwarding every method (a small forwarding base or mixin), or document the cost; and a convention for the catalog's fakes (a `sample()` factory per ViewData class, one shared no-op implementation per actions interface) so a new field touches one place.
4. Decide the build-observation seam: either keep a `probe` hook in `assemble` (documented as test-only) or give `Connect` an optional counter hook in `cubit_ui_flow`.
5. Lint to consider: a non-widget class holding a `BuildContext`.
6. The tree in this plan omitted the workspace switcher and the status view; the real `HomeView` takes four finished children (header, tabs, search, status) plus `onStartFlow`. Keep the plan's tree in sync.
7. Mention in the pattern doc that scope reads belong in `build`, not `initState`.

Not tested here, as stated above: cross-cubit coordination with no UI, toasts, the Widgetbook adapter, coexistence with old lint rules, `AppScreen`/`ScreenRoute`, localisation.
