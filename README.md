# systematic_flutter

The shared Flutter foundation for the apps (Episutra, Quanitya, Pocketcoder, Achaean, archescope): one repo, several independent packages, pinned by commit except the two versioned ones (see Versions).

## Packages

| Folder | Pub name | What it is |
|---|---|---|
| `packages/l10n` | `l10n_key_resolver` | runtime types for typed localized labels (`Label`, `L10nKey`, `DataText`); the generator is `l10n_generator` |
| `packages/systematic_failure` | `systematic_failure` | pure-Dart failure classification and stable error descriptions; depends on `l10n` |
| `packages/cubit_ui_flow` | `cubit_ui_flow` | cubit state to UI feedback: `MessageKey`, listener, exception mapping |
| `packages/ui` | `systematic_ui` | design tokens (`AppSizes`, `VSpace`, `HSpace`, `AppPadding`, `UiScaler`), `ThemeService`, layout widgets |
| `packages/catalog` | `systematic_catalog` | dev catalog page: every widget and screen state in light and dark, with live colour, font and scale tokens |
| `packages/lints` | `systematic_lints` | analyzer plugin: design-token, label and cubit/adapter rules; options and path scoping come from the app's `lint_config.yaml` |
| `packages/color_palette` | `flutter_color_palette` | color system with generated themes and colorblind simulation |
| `packages/error_privserver` | `flutter_error_privserver` | privacy-preserving error capture for cubits; stores keys only, never user text |
| `packages/nav_snapshot` | `nav_snapshot` | startup routing state: snapshots of slow inputs, re-decided routes |

Packages are independent (no pub workspace). Use one from an app with a git dependency on a subfolder:

```yaml
cubit_ui_flow:
  git:
    url: <repo url>
    ref: <sha>
    path: packages/cubit_ui_flow
```

## Versions

Only `l10n_key_resolver` (`packages/l10n`) and `systematic_failure` have versions and tags. Every other package is pinned by commit, as above.

Ask for the two by version range, never by `ref` or `path`, in apps, in libraries that use them (such as anonaccount_sdk) and in this repo's own packages. The example app (`examples/spike_app`) is the exception: it uses every package by folder. Then a library and an app can move to different commits of the rest of this repo without a clash:

```yaml
systematic_failure:
  git:
    url: https://github.com/qtpi-bonding-org/systematic_flutter.git
    path: packages/systematic_failure
    tag_pattern: "systematic_failure-v{{version}}"
  version: ^0.1.1
l10n_key_resolver:
  git:
    url: https://github.com/qtpi-bonding-org/systematic_flutter.git
    path: packages/l10n
    tag_pattern: "l10n_key_resolver-v{{version}}"
  version: ^0.2.0
```

- Needs Dart 3.9 or newer in the package that declares it.
- Any change to either package: bump its version in its pubspec and tag that commit `<pub name>-v<version>`. While at 0.x, a breaking change bumps the minor version.
- Inside this repo, each package's `pubspec_overrides.yaml` points the two back at their folders, so local edits are seen. These files are ignored when a package is used from git.
- `error_privserver` uses `cubit_ui_flow` by folder: pin both at the same commit, or override `cubit_ui_flow` in the app.

How to build UI with these packages (adapters, views, scopes, catalog, lints): [`docs/boundaries.md`](docs/boundaries.md).

## Layering (dependencies point down only)

1. `l10n`: no widgets, no Flutter.
2. `systematic_failure`: pure Dart; may use `l10n`; `cubit_ui_flow` and `error_privserver` will later use it.
3. `cubit_ui_flow`: may use `l10n` and `systematic_failure`.
4. `ui`: may use `l10n` and `color_palette`.
4. `error_privserver`: uses `cubit_ui_flow`.
5. `nav_snapshot`: independent.
6. `color_palette`: independent.
7. `catalog`: independent (takes entries and a theme builder from the app; no other package needed).
8. `lints`: independent (an analyzer plugin; it reads source, it does not depend on the other packages).

## History

Each package was imported with `git subtree add` (no squash), so the original commit SHAs, and therefore the refs apps pin today, are reachable. Imported sources:

| Package | Source repo | Imported at |
|---|---|---|
| `l10n` | `dart_l10n_key_resolver` | `52e2dbc` |
| `cubit_ui_flow` | `flutter_cubit_ui_flow` | `43deb62` |
| `ui` | `systematic_ui` | `ad5088b` |
| `nav_snapshot` | `flutter_nav_snapshot` | `704a9dd` |
| `color_palette` | `flutter_color_palette` | `e8755f5` |
| `lints` | `flutter_lint_generator` (`my-libs`) | `8537c34` |
| `error_privserver` | `flutter_error_privserver` | `d9e9355` (local patch commit on top of `be38ae6`) |

The old repos are not changed by this consolidation. See `docs/plans/` for the plan.
