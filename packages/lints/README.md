# systematic_lints

An analyzer plugin. Findings show in `dart analyze` and in the editor. (`flutter analyze` did not show them in our trial; use `dart analyze` in CI.)

## Rules are on by default

Every rule is registered as a warning rule, so **it runs unless the app turns it off** with `rule_name: false` under `diagnostics:`. A forgotten entry therefore means the rule runs, not that it is silently skipped. Severity stays `info`. The plugin itself still has to be listed under `plugins:`; the probe check proves it loaded. Listing rules as `true` is optional but documents intent:

```yaml
plugins:
  systematic_lints:
    git:
      url: https://github.com/qtpi-bonding-org/systematic_flutter.git
      ref: <same ref as the other packages>
      path: packages/lints
    diagnostics:
      actions_avoid_bloc_names: true
      actions_return_void: true
      adapter_naming: true
      # backend_access_only_in_adapters replaces these two; turn them off when it is on.
      avoid_bloc_imports_in_widgets_dir: false
      avoid_getit_in_adapters_dir: false
      backend_access_only_in_adapters: true
      cubit_field_selector_must_be_equatable: true
      exceptions_extend_failure_base: true
      no_banned_constructors: true
      no_bare_catch_conversion: true
      no_build_context_fields: true
      no_duplicate_cubitfield_keys: true
      no_error_to_text: true
      no_hardcoded_colors: true
      no_hardcoded_font_family: true
      no_hardcoded_font_size: true
      no_hardcoded_padding: true
      no_hardcoded_strings: true
      no_inline_widget_composition_in_pages: true
      no_raw_app_sizes: true
      no_raw_sizedbox_spacing: true
      no_string_error_in_state: true
      require_cubitfield_over_raw_bloc_apis: true
      require_static_selector: true
      throw_only_failure_types: true
```

`tool/smoke.sh` fails when its probe rule is not listed or reports nothing; the ratchet (`tool/check_lints.sh`) fails when its `probe_file` does not report the `probe_rule`.

## Use in an app

`analysis_options.yaml`:

```yaml
plugins:
  systematic_lints:
    git:
      url: https://github.com/qtpi-bonding-org/systematic_flutter.git
      ref: <same ref as the other packages>
      path: packages/lints
```

`lint_config.yaml` at the app's root holds options and paths. Options are lists of globs or names:

```yaml
no_string_error_in_state:
  argument_names: [error]
  mutators: [withError, applyFlow]
no_error_to_text:
  allowed_files: [lib/generated/**]
  logger_types: [Logger, AppLogger]
```

Apps that enable `backend_access_only_in_adapters` turn OFF `avoid_bloc_imports_in_widgets_dir` (it covers the same ground) and `avoid_getit_in_adapters_dir` (subsumed: GetIt is banned in adapters too).

## Ratchet baseline

`tool/lint_baseline.py` keys findings as `file|rule=count`. A check fails only when a (file, rule) count rises or a new pair appears; moving a finding or editing above it is fine, and counts that drop are reported as improvements. `--update` rewrites the baseline. An old-format baseline (whole analyzer lines) is read and migrated on the next `--update`.

## Rules

Design tokens: `no_hardcoded_colors`, `no_hardcoded_font_size`, `no_hardcoded_font_family`, `no_hardcoded_padding`, `no_raw_sizedbox_spacing`, `no_raw_app_sizes`.
Labels: `no_hardcoded_strings`.
Structure and layering: `no_inline_widget_composition_in_pages`, `avoid_bloc_imports_in_widgets_dir`, `avoid_getit_in_adapters_dir`, `require_cubitfield_over_raw_bloc_apis`, `require_static_selector`, `cubit_field_selector_must_be_equatable`, `no_duplicate_cubitfield_keys`.
Boundaries (views, adapters, scopes; types matched by name):
- `backend_access_only_in_adapters`: views (widgets that are not adapters, their `State`s, `BuildContext` extensions, top-level functions returning `Widget` or taking a `BuildContext`; exempt a top-level function or a plain class with an `@adapterHelper` annotation, matched by name; a class extending Flutter's `Action` is exempt too, since adapters provide keybinding actions) may not use `context.read/watch/select`, `Provider.of`/`BlocProvider.of`/`RepositoryProvider.of`/`ScopeProvider.of`/`maybeOf`, bloc widgets, `UiFlowStateListener` (and `UiFlowListener`), `Connect`/`Connect2`/`ConnectFor`, or hold fields, parameters or casts of a `BlocBase` or `AppScope` subtype or a type declared under `data_paths` (default `/lib/data/`, `/lib/infrastructure/`); `GetIt` is banned in every widget, adapters included. A view also may not obtain a cubit or scope through a plain function or getter and use it (`final c = notesCubit(); c.rename()`, `appScope.notes.rename()`): any method target, property target or variable initializer whose static type is a `BlocBase` or `AppScope` subtype (type arguments included) is flagged. Top-level functions, getters and variables that return or hold such types are flagged unless they are `@adapterHelper` or in a composition root. A plain service class that holds a cubit or scope is still flagged: no wrapper classes. Option `composition_root_paths` (globs or substrings) exempts everything declared in bootstrap and router files (widgets, their States, closures, top-level functions), `GetIt` included.
- `adapter_naming`: subclasses of `AdapterWidget`, `StatefulAdapterWidget`, `CubitAdapter`, `MultiCubitAdapter` end in `Adapter`; no other `Widget` subclass does.
- `actions_avoid_bloc_names`: abstract, interface and mixin `*Actions` types (including `mixin class` and `mixin`) declare no member named `close`, `emit`, `onChange`, `onError`, `addError`, `state`, `stream`, `isClosed`.
- `actions_return_void`: instance members of abstract, interface and mixin `*Actions` types return `void` or `Future<void>`; instance fields are flagged.
- `no_build_context_fields`: no field may hold a `BuildContext` (nullable included), except in a `State` subclass or a mixin constrained to one.
- `require_static_selector` and `cubit_field_selector_must_be_equatable` also check the `select:` argument of `Connect`, `Connect2` and `ConnectFor`.

Failure discipline: `exceptions_extend_failure_base`, `throw_only_failure_types` (option `allowed_types`: extra exception type names that may be thrown, for wire exceptions generated by another framework), and `no_bare_catch_conversion` enforce failure boundaries. `no_string_error_in_state` flags a statically typed `String` passed to configured error named arguments of configured mutators. `no_error_to_text` flags `.toString()` and interpolation of statically known subtypes of `Exception` or `Error`. Its `allowed_files` and `logger_types` options suppress intentional conversions; a logger suppression applies when the conversion is an argument of a call whose receiver has that static type name. A catch variable typed only `Object?` is not flagged (the rule intentionally relies on static types).

## Lint ratchet

`tool/check_lints.sh` reads a small YAML config (see `tool/lint_ratchet.example.yaml`) specifying package directories, a baseline path, and a probe rule. It runs `dart analyze`, verifies the plugin probe, and compares findings with the baseline. `tool/lint_baseline.py --update` refreshes it. The dependency-free self-test is `python3 tool/test_lint_baseline.py`.

First analyze after setup can report nothing while the plugin builds; use `tool/smoke.sh` before trusting a clean result.
