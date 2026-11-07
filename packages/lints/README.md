# systematic_lints

An analyzer plugin. Findings show in `dart analyze` and in the editor. (`flutter analyze` did not show them in our trial; use `dart analyze` in CI.)

## Use in an app

`analysis_options.yaml`:

```yaml
plugins:
  systematic_lints:
    git:
      url: git@github.com:qtpi-bonding-org/systematic_flutter.git
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

## Rules

Design tokens: `no_hardcoded_colors`, `no_hardcoded_font_size`, `no_hardcoded_font_family`, `no_hardcoded_padding`, `no_raw_sizedbox_spacing`, `no_raw_app_sizes`.
Labels: `no_hardcoded_strings`.
Structure and layering: `no_inline_widget_composition_in_pages`, `avoid_bloc_imports_in_widgets_dir`, `avoid_getit_in_adapters_dir`, `require_cubitfield_over_raw_bloc_apis`, `require_static_selector`, `cubit_field_selector_must_be_equatable`, `no_duplicate_cubitfield_keys`.

Failure discipline: `exceptions_extend_failure_base`, `throw_only_failure_types`, and `no_bare_catch_conversion` enforce failure boundaries. `no_string_error_in_state` flags a statically typed `String` passed to configured error named arguments of configured mutators. `no_error_to_text` flags `.toString()` and interpolation of statically known subtypes of `Exception` or `Error`. Its `allowed_files` and `logger_types` options suppress intentional conversions; a logger suppression applies when the conversion is an argument of a call whose receiver has that static type name. A catch variable typed only `Object?` is not flagged (the rule intentionally relies on static types).

## Lint ratchet

`tool/check_lints.sh` reads a small YAML config (see `tool/lint_ratchet.example.yaml`) specifying package directories, a baseline path, and a probe rule. It runs `dart analyze`, verifies the plugin probe, and compares findings with the baseline. `tool/lint_baseline.py --update` refreshes it. The dependency-free self-test is `python3 tool/test_lint_baseline.py`.

First analyze after setup can report nothing while the plugin builds; use `tool/smoke.sh` before trusting a clean result.
