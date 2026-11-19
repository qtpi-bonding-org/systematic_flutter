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
6. gp reads the code and it does not feel like ceremony. If it does, simplify before phase 1.

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
