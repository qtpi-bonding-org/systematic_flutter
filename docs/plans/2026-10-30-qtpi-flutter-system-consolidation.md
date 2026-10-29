# qtpi_flutter_system: consolidate the shared Flutter libraries (plan, rev 2 after review)

Decided with gp, 2026-10-29/30. Local repo only. No GitHub remote, no push, no change to any app or old repo without asking.

## Goal

One repo, one ref, several packages, so every app pins the same version of the shared pieces (`cubit_ui_flow` is pinned to four different refs today; `l10n_key_resolver` to two). Then make the framework changes (typed localized labels, shared semantics) once, inside it.

## What the review changed

- **No pub workspace.** Plain repo of independent packages, each with its own pubspec, lints and SDK constraint. This avoids the SDK floor (all four sources say `>=3.0.0`; workspaces need `^3.6`), the `flutter_lints` ^5 vs ^3 conflict, `dart pub get` failing on Flutter members, and the unproven "git dependency on a workspace member" question. A workspace can be added later if wanted.
- **Cross-package dependencies** (future: `cubit_ui_flow` and `ui` use `l10n`) use relative `path: ../l10n`. Pub resolves these inside a git checkout. Proven by a scratch consumer in step 7 BEFORE anything depends on it.
- **Baselines come from clean clones** of each pinned SHA made in the scratchpad, never from `pub get` inside a source repo (that would modify the tracked `pubspec.lock` of `cubit_ui_flow` and `l10n_key_resolver` and dirty the source).
- **The empty repo `~/Documents/qtpi_flutter_system` already exists** (`git init`, zero commits). Step 1 makes the first commit.
- **Do not strip tokens.** `AppSizes.qrCodeSize` is used by Quanitya; opacity tokens (`opacityGhost`, `opacityDisabled`) by Episutra; legacy `sizeNN` getters by both. They stay in v1; only comments may change, in a separate commit.
- **qtpi_ui `example/` is deleted with the storybook** (it imports it), together with the stale storybook specs/plans.
- **Constraints to respect:** Quanitya deep-imports `package:qtpi_ui/src/primitives/app_sizes.dart` and `src/structures/ds_{column,row,group}.dart`, so those `lib/src` paths do not move. Episutra and Quanitya depend on `~/Documents/qtpi_ui` by relative path, so the old folder stays where it is, untouched, still dirty.
- **Licensing:** no source repo has a LICENSE file (two READMEs say MIT). Not added now; gp decides.
- **Unpushed work:** qtpi_ui `main` is 4 commits ahead of origin and has uncommitted storybook edits; those commits come in via subtree, the uncommitted edits do not.

## Packages in v1

| Folder | Pub name (kept) | Source @ SHA | Notes |
|---|---|---|---|
| `packages/l10n` | `l10n_key_resolver` | `~/Documents/dart_l10n_key_resolver` @ `52e2dbc` | pure-Dart build_runner generator |
| `packages/cubit_ui_flow` | `cubit_ui_flow` | `~/Documents/my-libs/flutter_cubit_ui_flow` @ `43deb62` | |
| `packages/ui` | `qtpi_ui` | `~/Documents/qtpi_ui` @ `ad5088b` (local main, includes 4 unpushed commits) | storybook half removed |
| `packages/nav_snapshot` | `nav_snapshot` | `~/Documents/my-libs/flutter_nav_snapshot` @ `704a9dd` | used by Pocketcoder |

Not in v1: `flutter_widgetsystem`, `flutter_adaptable_group`, `ag_ui_widgets_flutter`, `flutter_lint_generator`.

## Steps

1. **Baselines.** Clone each source at its pinned SHA into the scratchpad (read-only use of the sources), run `flutter pub get`, `flutter analyze` (or `dart analyze` for the pure-Dart one) and `flutter test` there, record pass counts and analyzer issue counts. Record each source repo's `git status` and HEAD.
2. **First commit** in `~/Documents/qtpi_flutter_system`: root `README.md` (layering rules, imported SHAs), root `.gitignore` (`.dart_tool/`, `build/`, `pubspec.lock`, `.idea/`), `docs/` with this plan.
3. **Import** with `git subtree add --prefix=packages/<folder> <source path> main` (no `--squash`, so every original SHA stays reachable). Commit messages record the imported SHA.
4. **Housekeeping** (one commit): `git rm` the tracked `pubspec.lock` files in `l10n` and `cubit_ui_flow`; fix `cubit_ui_flow`'s README links if trivially wrong (no content changes).
5. **Slim `qtpi_ui`** (one commit): delete `lib/storybook.dart`, `lib/src/storybook/`, `test/storybook/`, `example/`, the stale storybook specs/plans, README storybook sections, and the `flutter_colorpicker` dependency. Nothing else.
6. **Verify each package** from its own folder in the new repo: `flutter pub get`, analyze, tests. Compare counts with the baselines (expected: identical except `qtpi_ui` loses its 11 storybook test files).
7. **Scratch consumer** (in the scratchpad, not in any repo): a throwaway Flutter app whose pubspec depends on each package via `git: {url: file://…/qtpi_flutter_system, path: packages/<folder>}`, run `flutter pub get`, import one symbol from each. Also one test with a package that depends on a sibling by `path: ../x`.
8. **Reachability check:** `git merge-base --is-ancestor` for every SHA an app pins today (cubit_ui_flow `fcac66a`, `737f24b`, `6692e2d`, `78ca8da`; l10n_key_resolver `d7a30df`, `52e2dbc`; nav_snapshot `704a9dd`) against the new history. The subtree import without squash should make the source-repo SHAs reachable.
9. **Confirm the sources are unchanged:** `git status` and HEAD identical to step 1 for all four (qtpi_ui stays dirty, as before).

## Out of scope (separate plans, in order)

1. `l10n`: typed `L10nKey`/`DataText`, typed parameterized keys, locale-completeness check. Breaking; apps stay on old pins until bumped.
2. `cubit_ui_flow`: `MessageKey` takes the typed key; consolidate the `UiFlowListener` variants.
3. `ui`: shared semantics wrapper (`ControlId`, `SpokenText`, `ControlBehavior`, `EpisutraSemantics`) moved from `episutra_core`, freezed with generated files committed (precedent: `ag_ui_widgets_flutter`).
4. Episutra repoints to one ref and adopts typed labels; architecture tests for hardcoded labels and raw tappables.
5. Later: LICENSE decision, root check script, lints unification, optional pub workspace.

## Done when

All four packages are in `~/Documents/qtpi_flutter_system` with history; each passes analyze and tests at the baseline counts (qtpi_ui minus storybook tests); no `pubspec.lock`, `build/` or `.dart_tool/` tracked; every previously pinned SHA is an ancestor of the new HEAD; the scratch consumer resolves all four via `git … path:`; source repos unchanged (same HEAD and same dirty state as recorded in step 1).
