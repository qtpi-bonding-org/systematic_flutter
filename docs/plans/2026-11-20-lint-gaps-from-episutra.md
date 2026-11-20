# Lint gaps found by the Episutra adoption

Episutra adopted the boundary framework fully (November 2026) and reached zero
findings. Its final sweeps still found code that breaks the rules in
`docs/boundaries.md` but passes the lints. Three gaps follow, each with the
evidence and a proposed rule change. Nothing here is implemented yet.

## 1. `backend_access_only_in_adapters` misses an inline call from a view

The rule flags a view that **holds** backend state: a field, parameter, cast or
local of a type under `data_paths`, plus `context.read/watch`, bloc widgets and
`GetIt`. It does not flag a view that **calls a function returning such a type
and uses the result in the same expression**, without naming the type:

```dart
class _FooState extends State<Foo> {
  @override
  void initState() {
    super.initState();
    ambientLogger('Foo').debug('mounted', category: LogCategory.ui);
  }
}
```

`ambientLogger(...)` returns `AppLogger` (under `data_paths`), but nothing in
the view declares that type, so the lint is silent. The same view written with
a getter (`AppLogger get _log => ambientLogger('Foo');`) is flagged. The rule
depends on how the code is written, not on what the view reaches.

**Proposed:** flag a view when the static type of any expression it evaluates
(the target of a method call or property access, or an argument) is declared
under `data_paths`, not only when a declaration names it. Exempt, as today:
`@adapterHelper` functions and classes, adapters, and the composition-root
paths. Also treat a top-level declaration in a view file (a top-level `_log`
getter) as part of the view.

**Evidence:** `streaming_indicator.dart`, `support/diagnostics/ticker_probe.dart`
and `graph_canvas_view.dart` (a top-level `_log` getter) logged from views and
were not flagged. `DockedSidePanel` and `A2uiSurface`, which used the getter
form, were.

## 2. Service location outside the composition root

`avoid_getit_in_adapters_dir` and `avoid_bloc_imports_in_widgets_dir` exist but
only check imports, and only in files under `adapters/` or `widgets/`. Nothing
checks how dependencies are obtained elsewhere. All of these passed:

- `getIt<T>()` inside `build` of the app root widget (`lib/app/app.dart`), and
  `GetIt.instance<T>()` as a fallback inside two cubit constructors.
- Plain `Provider<T>` above the app plus `context.read<T>()` in adapters, for
  app-lifetime services (a clock, a split-ratio store, message mappers) that
  belong on a scope.
- A service's static logger read from GetIt instead of `ambientLogger`.

**Proposed rules:**
- `no_service_locator_outside_composition_root`: `GetIt` only in files listed
  in `lint_config.yaml` (bootstrap, injection config) and inside a scope's
  `fromGetIt` factory.
- `adapters_read_scopes`: in adapters, `context.read`/`Provider.of` only for
  types listed as tree-local in `lint_config.yaml` (Episutra keeps two: a
  focus cursor and a per-tab jump controller). Everything else comes from a
  scope.

## 3. A ratchet script that keeps its own rule list hides enabled rules

Episutra's baseline script counted findings only for rules in a hand-written
list. After `avoid_bloc_imports_in_widgets_dir` was enabled in
`analysis_options.yaml`, its findings were dropped and the check passed. The
script now reads the enabled rules from the `diagnostics:` blocks.

**Proposed:** ship the baseline ratchet with the lints package (the probe check
in `tool/smoke.sh` is already there), reading the rule list from
`analysis_options.yaml`, and proving each analyze run with a probe finding so
an empty result can be trusted.
