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
    diagnostics:
      no_hardcoded_colors: true
      no_hardcoded_font_size: true
      no_hardcoded_padding: true
      no_raw_sizedbox_spacing: true
      no_hardcoded_strings: true
```

`lint_config.yaml` at the app's root holds the options and the paths each rule looks at:

```yaml
exclude: [test/**, "**/*.g.dart", "**/*.freezed.dart", "**/*.stories.dart"]  # these are the defaults
no_hardcoded_colors:
  banned_types: [Colors]
  exclude: [lib/design_system/storybook/**]   # added to the global excludes
no_hardcoded_strings:
  include: [lib/features/**]                  # only these paths; ignores the global excludes
no_inline_widget_composition_in_pages:
  page_suffix: Page
```

No generator step: the plugin reads the file when it analyzes, and re-reads it when it changes.

## First run

The first analyze after setup can report nothing while the plugin builds. Run `tool/smoke.sh <app dir>` (it plants a known violation and retries) before trusting a clean result in CI.

## Rules

Design tokens: `no_hardcoded_colors`, `no_hardcoded_font_size`, `no_hardcoded_font_family`, `no_hardcoded_padding`, `no_raw_sizedbox_spacing`, `no_raw_app_sizes` (a read of the static `AppSizes` scale where the theme supplies it; `allowed_members` defaults to `[font*]`, a trailing `*` allows a prefix).
Repo choices: `no_banned_constructors` bans types a repo has decided against. The list is the repo's own and the rule does nothing without one: `banned: [RoundedRectangleBorder, BorderRadius.circular]`, where an entry is a type name (every constructor) or `Type.constructor`.
Labels: `no_hardcoded_strings` (a literal in `Text(...)` or in `tooltip:`, `hintText:`, `label:` and similar; set `text_arguments` to change the list).
Structure: `no_inline_widget_composition_in_pages`.
Layering: `avoid_bloc_imports_in_widgets_dir`, `avoid_getit_in_adapters_dir`, `require_cubitfield_over_raw_bloc_apis`, `require_static_selector`, `cubit_field_selector_must_be_equatable`, `no_duplicate_cubitfield_keys`.
