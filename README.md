# systematic_flutter

The shared Flutter foundation for the apps (Episutra, Quanitya, Pocketcoder, Achaean, archescope): one repo, one ref, several independent packages.

## Packages

| Folder | Pub name | What it is |
|---|---|---|
| `packages/l10n` | `l10n_key_resolver` | build_runner generator: ARB keys to a resolver and typed key constants |
| `packages/cubit_ui_flow` | `cubit_ui_flow` | cubit state to UI feedback: `MessageKey`, listener, exception mapping |
| `packages/ui` | `systematic_ui` | design tokens (`AppSizes`, `VSpace`, `HSpace`, `AppPadding`, `UiScaler`), `ThemeService`, layout widgets |
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

## Layering (dependencies point down only)

1. `l10n`: no widgets, no Flutter.
2. `cubit_ui_flow`: may use `l10n`.
3. `ui`: may use `l10n`.
3. `error_privserver`: uses `cubit_ui_flow`.
4. `nav_snapshot`: independent.

## History

Each package was imported with `git subtree add` (no squash), so the original commit SHAs, and therefore the refs apps pin today, are reachable. Imported sources:

| Package | Source repo | Imported at |
|---|---|---|
| `l10n` | `dart_l10n_key_resolver` | `52e2dbc` |
| `cubit_ui_flow` | `flutter_cubit_ui_flow` | `43deb62` |
| `ui` | `systematic_ui` | `ad5088b` |
| `nav_snapshot` | `flutter_nav_snapshot` | `704a9dd` |
| `error_privserver` | `flutter_error_privserver` | `d9e9355` (local patch commit on top of `be38ae6`) |

The old repos are not changed by this consolidation. See `docs/plans/` for the plan.
