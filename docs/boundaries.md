# Boundaries: how to build UI with this framework

Read this before you build or change UI in an app that uses `systematic_flutter` (Episutra first). It is written so you can make a change correctly with little reading. Reasons and history: `docs/plans/2026-11-19-boundary-framework.md`. Goals: `docs/ui-framework-goals.md`. The worked example is `examples/spike_app`; every concept below links to a real file there. Paths in links are relative to `docs/`.

## 1. The idea

Only **adapters** touch the backend (cubits, scopes, services, GetIt). **Views** only draw data they are given. A view takes plain values, callbacks and finished child widgets, so you can build it with made-up data and no cubit. That gives three things:

- The catalog can show every widget and screen in every state, using the same code the app uses.
- A typical change touches one to three obvious files.
- Lints can enforce it, so the rule survives agents and time.

Data flows down through two one-way streets and meets in the adapter:

```
down:  select : State -> ViewData        pure function, unit-tested without widgets
up:    XActions                          interface the cubit implements, one method per user intent
glue:  Connect(select, builder)          framework widget; builder calls the adapter's assemble()
```

## 2. Roles

| Role | Is | May | May not |
|---|---|---|---|
| Cubit | State holder. Implements its `XActions`. | Hold state, call services, emit | Open dialogs, navigate, know widgets |
| `XActions` | Interface of plain cubit calls | Methods returning `void` or `Future<void>` | Fields; return values; names like `close`, `emit`, `state`, `stream`, `onChange`, `onError`, `addError`, `isClosed`; anything that needs UI (use a callback) |
| `select` / ViewData | Pure function `State -> ViewData`; ViewData is a value class with `==`/`hashCode` (use `@freezed` in apps that have it) and a `samples()` map | Map and format state | Be a closure (must be static or top-level); hold cubits |
| `Connect`, `Connect2`, `ConnectFor` | Framework widgets (`cubit_ui_flow`) | Subscribe, select, rebuild on a changed ViewData | Live inside views |
| Adapter | Subclass of `AdapterWidget` or `StatefulAdapterWidget`, named `*Adapter` | Use `Connect*`, `BlocProvider`, `ScopeProvider.of`, `UiFlowStateListener`; own controllers; open dialogs; navigate; provide `Action`s for `Intent`s | Use `GetIt` |
| View | Any other widget (including small ones like `TagChip`), `BuildContext` extensions, top-level functions returning `Widget` | Take data, callbacks, finished children, controllers/listenables; read `Theme`, `MediaQuery`, `Directionality`, `Localizations`, `DefaultTextStyle`, `FocusScope`; use `Shortcuts` (dispatch `Intent`s); local UI state | `context.read/watch/select`, `Provider.of`, bloc widgets, `UiFlowStateListener`, `ScopeProvider.of`, `Connect*`, `GetIt`; fields, parameters or casts of a cubit type, an `AppScope` type, or a type declared under the app's `data_paths` |
| Scope | Subclass of `AppScope` (plain class, not a widget) | Own long-lived cubits with `own(...)`; expose factories for local cubits; use `GetIt` | Be a widget |
| Composition root | Everything declared in files listed as `composition_root_paths` (bootstrap, router: `MyApp` and its State, top-level functions, route closures) | `GetIt`; build scopes; fill top-level children with adapters | |

Data and services are never ambient. Only theme-like context is.

Examples: cubit and ViewData [`notes_cubit.dart`](../examples/spike_app/lib/notes/notes_cubit.dart); adapter [`note_tile_adapter.dart`](../examples/spike_app/lib/adapters/note_tile_adapter.dart); view [`note_tile.dart`](../examples/spike_app/lib/views/note_tile.dart); scopes [`scopes.dart`](../examples/spike_app/lib/scopes.dart); composition root [`app.dart`](../examples/spike_app/lib/app.dart).

An adapter has this shape:

```dart
class NoteTileAdapter extends AdapterWidget {
  const NoteTileAdapter({super.key, required this.tabId, required this.id});
  final String tabId;
  final String id;

  @override
  Widget build(BuildContext context) {
    return ConnectFor<NotesCubit, NotesState, String, NoteTileData?>(
      arg: id,
      select: selectNote,                       // static / top-level
      resolve: (c) => ScopeProvider.of<WorkspaceScope>(c).notesFor(tabId),
      debugLabel: 'tile:$id',
      builder: (ctx, data, cubit) => data == null
          ? const SizedBox.shrink()
          : assemble(data, cubit, onRename: ..., onDelete: ...),
    );
  }

  // Pure. The app and the catalog both call this.
  static Widget assemble(NoteTileData data, NotesActions actions,
      {required VoidCallback onRename, required VoidCallback onDelete}) { ... }
}
```

Rules for `assemble`: static, pure, takes ViewData, an actions interface, UI callbacks and finished children, returns a widget. No cubit, no context lookups inside.

The Connect family (all in `package:cubit_ui_flow/cubit_ui_flow.dart`):

| Widget | Use when | `select` shape |
|---|---|---|
| `Connect<C, S, D>` | one cubit | `D Function(S)` |
| `Connect2<C1, S1, C2, S2, D>` | two cubits into one view (`resolve1`, `resolve2`) | `D Function(S1, S2)` |
| `ConnectFor<C, S, A, D>` | one entry of keyed state, e.g. one list item (`arg:`) | `D Function(S, A)` |

All three: `select` must be static or top-level (its identity is the cache key; a closure defeats it; lints check). `resolve: (context) => cubit` reads the cubit from a scope; without it they use `context.read<C>()`. `resolve` runs on every build and a changed cubit or selector resubscribes, so an id-dependent connection follows its id without a key. The builder gets `(context, data, cubit)` (`Connect2`: `(context, data, cubit1, cubit2)`). `debugLabel` is reported to `ConnectObserver` (section 6). The type arguments are long and cannot be inferred from a tear-off; that is known (section 11).

## 3. The three kinds of arguments

A widget argument is one of:

| Kind | Looks like | Example |
|---|---|---|
| Data | values, ViewData | `data: NoteTileData` |
| Callbacks | `on...`, the up street | `onSelect`, `onDelete` |
| Finished children | `Widget`, or `Widget Function(...)` for lists | `trailing: TagChip(...)`, `itemBuilder: (id) => ...` |

Leaves take data and callbacks. Containers take data for what they draw themselves and finished children for everything else. The adapter builds the pieces; the catalog builds them from fakes.

**The tell: an argument the widget only passes on.** If a container takes `tag` and `onTagTap` just to hand them to a chip it builds, make the chip a finished child.

```dart
// before: Tile builds the chip, so it must carry the chip's arguments
Tile(title: t, tag: tag, onTagTap: tap)

// after: Tile takes the finished chip; the adapter builds it
Tile(title: t, trailing: TagChip(data: TagChipData(label: tag), onTap: tap))
```

A view may fill a child position itself only with something that needs no data or actions (a fixed icon). Lists work the same way: the list adapter selects only ids, the list view takes `itemBuilder(id)`, and each item is its own adapter with its own `ConnectFor`. See [`notes_adapter.dart`](../examples/spike_app/lib/adapters/notes_adapter.dart) and [`home_view.dart`](../examples/spike_app/lib/views/home_view.dart) (four finished children).

## 4. Lifetime

Default: **state lives on the tree**, with the UI it serves.

| State | Where it lives |
|---|---|
| Local state tied to a piece of UI (dialog form, a settings section) | The adapter provides it with `BlocProvider`, created from a scope factory, never `GetIt`. Disposed with that UI. Example: [`rename_dialog_adapter.dart`](../examples/spike_app/lib/adapters/rename_dialog_adapter.dart) (`newRenameForm`). |
| Per-instance state (one cubit per tab) | On the tree if it dies with the widget. In a scope keyed by instance id if it must survive the widget leaving (a tab switched out). Example: `WorkspaceScope.notesFor(tabId)`. |
| State that outlives the UI around it (survives a workspace switch, spans routes, shared by distant regions) | An `AppScope`. |

**Scopes.** An `AppScope` is a plain class; `own(cubit)` registers things to close on `dispose()`. A `ScopeProvider<T>` puts it on the tree at the node whose life it shares:

```dart
ScopeProvider<SessionScope>(create: () => SessionScope(...), child: ...)
final scope = ScopeProvider.of<SessionScope>(context);   // throws if missing; maybeOf returns null
```

- `create` runs once (in `initState`) and the scope is disposed with the provider. Never build a scope inside a builder closure; it would be recreated.
- `ScopeProvider.of` does not subscribe, so it works in `initState` and in `BlocProvider(create:)`. `SearchAdapter` reads the scope in `initState` ([`search_adapter.dart`](../examples/spike_app/lib/adapters/search_adapter.dart)).
- To replace a scope, key its provider: `ScopeProvider<WorkspaceScope>(key: ValueKey(id), ...)`. The old scope disposes and the subtree gets a new one. See [`workspace_host_adapter.dart`](../examples/spike_app/lib/adapters/workspace_host_adapter.dart).
- `ScopeProvider.value(scope: ...)` exposes a scope you own; it is never disposed by the provider.

**Flows across routes.** Put a `ShellRoute` over the flow's routes and a `ScopeProvider` in its builder. Steps read the same cubit; leaving the flow disposes it. No `state.extra`. See `ShellRoute` in [`app.dart`](../examples/spike_app/lib/app.dart) and `FlowScope` in `scopes.dart`.

**Dialogs and the Navigator.** A dialog route is built under the Navigator. It sees only scopes provided above the Navigator (the spike's `SessionScope` sits above `MaterialApp`). A scope provided inside a route (`WorkspaceScope`) is invisible to a dialog. The adapter that opens the dialog passes what it needs as arguments (`onSubmit: (t) => cubit.rename(id, t)`).

## 5. Actions and UI callbacks

`XActions` holds only calls a view may make straight on the cubit:

```dart
abstract class NotesActions {
  Future<void> select(String id);
  Future<void> rename(String id, String title);
  void cycleTag(String id);
  Future<void> reload();
}
class NotesCubit ... implements NotesActions { ... }
```

Rules:

- Return `void` or `Future<void>` only (`actions_return_void`). This is what lets `NoOpActions` fake any interface.
- No member named like `BlocBase` API: `close`, `emit`, `onChange`, `onError`, `addError`, `state`, `stream`, `isClosed` (`actions_avoid_bloc_names`). A clash would make the cubit's own method satisfy the interface by accident.
- An action that needs UI (confirm dialog, navigation, toast) is not in the interface. The adapter passes a **callback** to the view. Write it as a small top-level function marked `@adapterHelper` so it may use backend types:

```dart
// views take onDelete; the adapter wires it:
onDelete: () => confirmAndDelete(ctx, cubit, id),

@adapterHelper
Future<void> confirmAndDelete(BuildContext context, NotesCubit cubit, String id) async {
  // show dialog, then cubit.delete(id)
}
```

See [`confirm_and_delete.dart`](../examples/spike_app/lib/adapters/confirm_and_delete.dart). Do not write a forwarding wrapper class around the cubit. Cubits never open dialogs.

Keybindings: a view dispatches an `Intent` (`DeleteSelectedIntent` in `note_list_view.dart`); the adapter provides the `Action` that does the backend work (`NotesAdapter.assemble`).

Toasts and loading: wrap with `UiFlowStateListener<Cubit, State>` inside the adapter (not in a view). It needs a mapper and an `IUiFlowService`. See [`notes_adapter.dart`](../examples/spike_app/lib/adapters/notes_adapter.dart) and [`notes_message_mapper.dart`](../examples/spike_app/lib/adapters/notes_message_mapper.dart). Compare events by identity, or the same toast will not repeat.

## 6. Performance

Rule: a change rebuilds only the widgets whose data changed.

- `Connect` runs its builder again only when the selected ViewData changes by `==`. So ViewData must have value equality, and `select` should pick only what the view shows.
- Keep adapters small. An adapter rebuild rebuilds everything it assembled.
- Lists: one adapter per item with `ConnectFor`. Renaming one note rebuilds one tile. Key item adapters by their identity (`ValueKey('$tabId/$id')`).
- High-frequency data (typing, pointer, scroll, graph panning, streaming) never goes through ViewData. Hand a `TextEditingController`, a `ValueListenable` or another controller down from the adapter. Example: the search field controller owned by `SearchAdapter`; the status tick shown by one small view.
- Count rebuilds in tests with `ConnectObserver` and `BuildCounter`:

```dart
class CountingObserver extends ConnectObserver {
  final counts = <String, int>{};
  @override
  void onBuild(String? label) { if (label != null) counts[label] = (counts[label] ?? 0) + 1; }
}
setUp(() => ConnectObserver.instance = CountingObserver());
tearDown(() => ConnectObserver.instance = null);
```

Give each `Connect*` a `debugLabel`; the observer counts builder runs per label. Production code carries no test probes. `BuildCounter` (`package:systematic_ui/testing.dart`) wraps a subtree and counts its `build`s by id (`BuildCounter.count(id)`, `BuildCounter.reset()` in `setUp`); use it for things that are not a `Connect`. Examples: [`rebuild_test.dart`](../examples/spike_app/test/rebuild_test.dart), [`helpers.dart`](../examples/spike_app/test/helpers.dart). When you touch a hot path (typing, panning, streaming), add or keep a count test.

## 7. The catalog

`systematic_catalog` shows every widget and screen in every state, light and dark side by side, with live colour, font and scale controls. Widgets first, screens below. It shows the app's real widgets, built through the same `assemble` functions.

Per ViewData, write `samples()` next to the class:

```dart
static Map<String, NoteTileData> samples() => const {
  'default':    NoteTileData(id: 'a', title: 'Alpha', tag: 'tag1', selected: false),
  'selected':   NoteTileData(id: 'a', title: 'Alpha', tag: 'tag1', selected: true),
  'long title': NoteTileData(id: 'a', title: 'A very long ... wraps', tag: 'tag1', selected: false),
};
```

- Name every state the widget can be in: default, selected, long text, empty, **loading**, **error**, as they apply.
- A sealed ViewData (status variants) needs a sample per variant, and a test that fails if one is missing. Pattern in [`samples_test.dart`](../examples/spike_app/test/samples_test.dart): an exhaustive `switch` that stops compiling when a variant is added, plus a covered-set check. `NoteListData.samples()` in `notes_cubit.dart` covers loading, error, empty, full.
- `CatalogEntry.fromSamples<T>(name:, kind:, samples:, build:)` makes one state per sample. States are never listed by hand in the catalog.
- Entries use `assemble` with fakes: `NoOpActions` for actions, literal data from `samples()`, finished children as plain widgets:

```dart
class _NoopNotes extends NoOpActions implements NotesActions {}   // no members, ever
final _notes = _NoopNotes();

CatalogEntry.fromSamples<NoteTileData>(
  name: 'NoteTile', kind: CatalogKind.widget,
  samples: NoteTileData.samples(),
  build: (d) => NoteTileAdapter.assemble(d, _notes, onRename: () {}, onDelete: () {}),
)
```

`NoOpActions` answers any call with a completed `Future<void>`. A new action method needs no change in the catalog.

- `kind` is explicit: `CatalogKind.widget` or `CatalogKind.screen` (screens render in 390x844 frames).
- Three toggles apply to every tile: Large text (2x), Narrow (320), Right-to-left. A tile that breaks under one of them is a bug in the widget.
- The side panel edits `CatalogTokens` (seed, `fontFamily`, `fontScale`, `spacingScale`, `sizeScale`, `colorOverrides`). The app's `themeBuilder(tokens, brightness)` maps them to its real theme and tokens; pass `paletteColors` for per-key swatches.
- A builder that throws shows an error tile; the page keeps working.
- Controllers that an adapter would own are owned in the catalog by a small wrapper that disposes them (`_WithController` in `catalog_main.dart`).

Run: `flutter run -t lib/catalog_main.dart -d macos` in the app. Test: [`catalog_test.dart`](../examples/spike_app/test/catalog_test.dart) checks every entry shows exactly its `samples()`, renders with no scopes or cubits, and survives the three toggles. The whole entry list is [`catalog_main.dart`](../examples/spike_app/lib/catalog_main.dart); API in `packages/catalog/README.md`.

## 8. Recipes

Counts are production files you edit. Files the compiler forces you to touch (a required new field breaks literals elsewhere) are listed separately.

**a) Show one more field on a tile (2 files).**
1. `notes_cubit.dart`: add the field to `NoteTileData`, to `selectNote`, and to each entry in `samples()`.
2. `views/note_tile.dart`: draw it.
The adapter does not change: `assemble` takes the whole `NoteTileData`. Forced: any other literal `NoteTileData` (catalog, tests). Make the field optional or put it in `samples()` only to avoid that.

**b) Add a button that calls a cubit action (3 files).**
1. `notes_cubit.dart`: add the method to `NotesActions` and `NotesCubit`.
2. `views/note_tile.dart`: add the button and an `onPin` callback.
3. `adapters/note_tile_adapter.dart`: pass `actions.pin(data.id)` in `assemble`.
Plus an ARB key for a tooltip. The catalog needs nothing (`NoOpActions`), except passing the new callback if `assemble` gained a parameter. If the action needs UI (confirm), make it a callback and a `@adapterHelper` function instead of an action.

**c) Add a named state (2 files).**
1. The ViewData file: add one entry to `samples()` (for a sealed type, add the variant and its sample, and update the coverage test).
2. The view: handle the state if it draws differently.
The catalog shows it by itself.

**d) Add a new screen region (3-4 files).**
1. ViewData, `select` and `samples()` (next to the cubit, or a new file).
2. `views/<name>_view.dart`: data, callbacks, finished children.
3. `adapters/<name>_adapter.dart`: `AdapterWidget` with a `Connect`, and `assemble`.
4. The parent: if it is a container, add a finished-child parameter (do not add the new region's arguments) and fill it with the adapter in the route; `catalog_main.dart`: add an entry. The route or `HomeView` call is the only place the new adapter is named.
A new cubit that must outlive its UI also needs a line in a scope (`own(...)`). Otherwise provide it on the tree.

**e) Restyle a widget (1 file).** Edit the view. Use tokens (`context.sizes`, `context.padding`, theme colours); hardcoded colours, sizes and strings are linted. Check it in the catalog in light, dark and the three toggles.

If a change needs more files than this, something is passing an argument through. Re-read section 3.

## 9. Lints

`systematic_lints` is an analyzer plugin. Findings show in **`dart analyze`** (not `flutter analyze`) and in the editor.

**Rules are off unless listed.** A rule missing from `plugins: systematic_lints: diagnostics:` in `analysis_options.yaml` reports nothing, and the result looks clean. List every rule (full list in `packages/lints/README.md`; a working file is [`analysis_options.yaml`](../examples/spike_app/analysis_options.yaml)). Per-app options live in `lint_config.yaml` ([example](../examples/spike_app/lint_config.yaml)).

Boundary rules:

| Rule | Says |
|---|---|
| `backend_access_only_in_adapters` | Views may not read backend (see section 2); `GetIt` banned in every widget; option `composition_root_paths` exempts everything declared in bootstrap/router files, `GetIt` included; `data_paths` names the types views may not hold; a plain class holding a cubit or scope is flagged too (no wrapper classes), except a class or top-level function marked `@adapterHelper` and a class extending Flutter's `Action` (keybinding actions provided by adapters). Other services are untouched unless they hold a cubit or scope |
| `adapter_naming` | Subclasses of `AdapterWidget`, `StatefulAdapterWidget`, `CubitAdapter`, `MultiCubitAdapter` end in `Adapter`; no other widget does |
| `actions_avoid_bloc_names` | `*Actions` types declare no member named like `BlocBase` API |
| `actions_return_void` | `*Actions` members return `void` or `Future<void>`; no fields |
| `no_build_context_fields` | No `BuildContext` field outside a `State` |
| `require_static_selector`, `cubit_field_selector_must_be_equatable` | Also check `select:` of `Connect`, `Connect2` and `ConnectFor` |

Other rules: design tokens (`no_hardcoded_colors`, `..._font_size`, `..._font_family`, `..._padding`, `no_raw_sizedbox_spacing`, `no_raw_app_sizes`), labels (`no_hardcoded_strings`), failure discipline (`exceptions_extend_failure_base`, `throw_only_failure_types`, `no_bare_catch_conversion`, `no_string_error_in_state`, `no_error_to_text`), and the older structure rules. Apps that opt in disable `avoid_bloc_imports_in_widgets_dir`; `avoid_getit_in_adapters_dir` is covered by the boundary rule. Types are matched by name, and rules apply to widgets and their `State`s only, so cubits and scopes are untouched, and a plain class is checked only for holding a cubit or scope (see the table). `*View` naming is deliberately not enforced.

**Probe check.** Because a missing entry is silent, two scripts prove the plugin works:
- `packages/lints/tool/smoke.sh <app> [rule]` fails if the rule is not listed under `diagnostics:` or the probe reports nothing.
- `tool/check_lints.sh` (the ratchet) analyzes `probe_file`, a file that deliberately violates `probe_rule`, and fails if it is not reported. Keep the probe file excluded from the app's normal analysis (`analyzer: exclude:`). The first analyze after setup can be empty while the plugin builds; the scripts retry.

**Ratchet.** `tool/lint_ratchet.yaml` names `package_dirs`, `baseline`, `probe_rule` and `probe_file` ([example](../examples/spike_app/tool/lint_ratchet.yaml); `probe_file` needs the `./tool/...` form when `package_dirs` is `[.]`, since matching is by prefix). The script runs `dart analyze`, then fails on any finding not in the baseline file. Findings already in the baseline are allowed, so existing code migrates a piece at a time. After really fixing findings, refresh: save the analyze output to a file and run `python3 tool/lint_baseline.py --baseline tool/lint_baseline.txt --update <file>`, and say so in the commit. Never add findings to the baseline to get past a new violation; fix the violation.

## 10. Adopting in an existing app

**Principle:** structure problems are fixed in the app; `data_paths` stays at its default. When an app's layout conflicts with the lints, reorganise the app; never tune or exempt the linter for it.

Order, from `docs/plans/2026-11-19-boundary-framework.md` (the plan has the Episutra specifics; also `2026-11-19-screens-and-catalog.md`):

1. **Pins.** Point every `systematic_flutter` dependency, including the lints plugin entries in both `analysis_options.yaml` files, at one https URL and one ref. Independent of the rest.
2. **Bump, enable rules, baseline.** List the new rules under `diagnostics:`, run the probe check, baseline what exists. The ratchet then blocks growth only.
3. **Migrate in this order:**
   - onboarding (a `ShellRoute` flow scope replaces `state.extra`; test that state carries across steps),
   - settings (including any window that re-provides cubits),
   - the shell last: scopes for notebook-level state (write notebook-switch tests first), per-tab state, keybindings via `Intent`/`Action` instead of GetIt lookups, then piece by piece, with `BuildCounter`/`ConnectObserver` checks on typing, graph panning and chat streaming.
   - **Before enabling the rule in Episutra:** move `packages/episutra_core/lib/data/models/` (26 files) and the view-facing domain exceptions to `lib/domain/`. Mechanical import rewrite (about 126 importing files). Then the default `data_paths` need no tuning.
   - **`UiFlowListener` services.** Episutra's `UiFlowListener` wrapper calls GetIt for `ILoadingService`, `IProgressService`, `IExceptionKeyMapper`, `LabelResolver` and `IFeedbackService`. Bundle them into one services object built in the composition root and provided through the session scope; the wrapper (an adapter-level widget) reads it with `ScopeProvider.of`. Behaviour is unchanged (feature mapper, then global exception mapper, then generic error). The wrapper is renamed `UiFlowListenerAdapter`, so each call site changes its name (Episutra had 11). Tests provide a fake bundle.
   - **Existing `CubitAdapter`/`MultiCubitAdapter`** keep working unchanged (there is no scope hook for them). When their screen migrates, rewrite them as `AdapterWidget` + `Connect`.
4. **Catalog.** Add `samples()` to each ViewData as you migrate; add entries; swap in the shared catalog.

Per piece: write the ViewData with `samples()`, `select` with a unit test, the actions interface, the view, the adapter with `assemble`, the catalog entry. Move the old widget's backend reads into the adapter and delete them from the view.

## 11. Known friction

- **Glue per feature.** A feature costs a cubit, state, ViewData (hand-written `==` in the spike; use `@freezed`), an actions interface, an adapter (25-75 lines), a view and a catalog entry. The value classes are the biggest cost.
- **Long `Connect` type arguments.** `select` is a tear-off, so they cannot be inferred. Write them out.
- **Rules silent when unlisted.** The most expensive trap. Run the probe check after any config change.
- **`flutter analyze` hides plugin findings.** Use `dart analyze`.
- **Data paths.** `backend_access_only_in_adapters` bans views from holding types declared under `data_paths` (default `/lib/data/`, `/lib/infrastructure/`), matched by substring of the file path. Convention: value types that views may use (models, domain exceptions, value interfaces) live in `lib/domain/`, never under `lib/data/`; `lib/data/` holds only backend code (dao, db, tables, sync, repositories, services, codecs, mappers). With that layout the default paths need no tuning. The spike moved its `NotesSource` interface into `lib/notes/` for this. The match is by substring, so a dependency package's own `lib/data/` files match the default too.
- **Toast setup is three pieces.** A message mapper needs `BaseStateMessageMapper`, `ClassifyingExceptionKeyMapper` and a `MessageKey`; `UiFlowStateListener` needs a `UiFlowService` with feedback and loading services (the spike uses a `NoLoading` stub). The listener class is `UiFlowStateListener`; older text calls it `UiFlowListener`, and the lint bans both names in views.
- **Error capture.** `ErrorInbox` creates its queue in the zone where `configure` runs; tests and the app need a `startErrorCapture` wrapper. Testing storage is a separate library (`flutter_error_privserver/testing.dart`).
- **Two l10n generators.** `flutter gen-l10n` and the build_runner `l10n_generator`; keep `build.yaml` and `l10n.yaml` aligned.
- **Theme extensions.** `ThemeService` needs the `SystematicSizes` extension added by hand to every theme, app and catalog, so the catalog needs a `themeBuilder`. A palette gives colours, not a `ThemeData`; the app maps it.
- **Catalog gaps.** Tile gaps are fixed at 16. The seed-colour row shows only when no `paletteColors` are given.
- **Dialogs miss inner scopes.** See section 4.
- **Cross-cubit coordination with no UI, `AppScreen`/`ScreenRoute`, a Widgetbook adapter** are not built or not proven by the spike. Do not assume them.
