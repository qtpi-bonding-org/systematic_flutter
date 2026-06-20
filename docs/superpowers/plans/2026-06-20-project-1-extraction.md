# `qtpi_ui` Project 1 — Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the shared design-system "bones" (tokens, ThemeService, structure primitives) from episutra + quanitya into a new local Flutter package (`qtpi_ui`) and migrate both apps to consume it via a path dependency.

**Architecture:** `qtpi_ui` is a Flutter package living at `/Users/aicoder/Documents/qtpi_ui`. Both apps add it as `path: ../../../qtpi_ui`. Shared code moves into `qtpi_ui/lib/src/`; per-app skin (palette values, fonts, app_theme, signature widgets) stays in each app. Dart `typedef` aliases (`EpisutraColumn = DsColumn`) mean zero call-site renames. `ThemeService` drops its `@singleton` annotation and each app registers it manually via `getIt.registerSingleton(ThemeService(...))`.

**Tech Stack:** Dart 3, Flutter SDK, `flutter_color_palette` (HTTPS, ref `e8755f5993cb66c6dfd4696df87bf6ef64229756`), `flutter_test` for widget tests, `get_it` (app-side only — `qtpi_ui` itself has no DI dependency).

## Global Constraints

- `qtpi_ui` depends ONLY on `flutter` + `flutter_color_palette`. No `injectable`, no `get_it`, no `cubit_ui_flow` — any of these in `qtpi_ui`'s pubspec.yaml is a defect.
- `flutter_color_palette` pinned to HTTPS URL `https://github.com/qtpi-bonding-org/flutter_color_palette.git` ref `e8755f5993cb66c6dfd4696df87bf6ef64229756` in `qtpi_ui/pubspec.yaml` AND in `app/episutra_flutter/pubspec.yaml` (exact same URL + ref). quanitya already has this pin; no change needed there.
- `ThemeService` in `qtpi_ui` has NO `@singleton` annotation and NO `import 'package:injectable/injectable.dart'` — it is a plain `ChangeNotifier` subclass taking palette(s) in the constructor.
- Dart `typedef` aliases live in each app's `lib/design_system/qtpi_aliases.dart`. No call sites in either app are renamed — if any existing call site stops compiling, the typedef or import is wrong, not the call site.
- `DsColumn`, `DsRow`, `DsGroup` names are used inside `qtpi_ui` only. Outside, apps use their existing names via typedef.
- `flutter analyze` must pass with zero errors in `qtpi_ui`, `episutra_flutter`, and `quanitya_flutter` after each task that touches those repos.
- No comments in code unless explaining a non-obvious invariant. No docstrings on simple getters.
- Working directory for qtpi_ui tasks: `/Users/aicoder/Documents/qtpi_ui`. For episutra tasks: `/Users/aicoder/Documents/episutra/app/episutra_flutter`. For quanitya tasks: `/Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter`.
- All qtpi_ui work happens on branch `feat/project-1-extraction`.
- Run `flutter pub get` from the package root before running any `flutter analyze` or tests.

---

## File Structure

### New files in `qtpi_ui/`

```
lib/
  qtpi_ui.dart                          ← public barrel export
  src/
    primitives/
      ui_scaler.dart                    ← UiScaler (verbatim from episutra)
      app_sizes.dart                    ← AppSizes (verbatim from episutra)
      app_spacings.dart                 ← AppPadding, VSpace, HSpace (verbatim)
    structures/
      ds_column.dart                    ← DsColumn (EpisutraColumn + mainAxisSize)
      ds_row.dart                       ← DsRow (EpisutraRow verbatim, renamed)
      ds_group.dart                     ← DsGroup (InkWell-based, no GlowTap)
    theme/
      theme_service.dart                ← ThemeService (no injectable, +overrides)
test/
  primitives/
    ui_scaler_test.dart
    app_sizes_test.dart
    app_spacings_test.dart
  structures/
    ds_column_test.dart
    ds_row_test.dart
    ds_group_test.dart
  theme/
    theme_service_test.dart
```

### Files modified in `episutra_flutter/`

```
pubspec.yaml                                      ← add qtpi_ui path dep + pin flutter_color_palette
lib/design_system/qtpi_aliases.dart               ← CREATE: typedef aliases
lib/design_system/theme/theme_service.dart        ← REPLACE body: no @singleton, register manually
lib/design_system/primitives/ui_scaler.dart       ← DELETE (moved to qtpi_ui)
lib/design_system/primitives/app_sizes.dart       ← DELETE (moved to qtpi_ui)
lib/design_system/primitives/app_spacings.dart    ← DELETE (moved to qtpi_ui)
lib/design_system/structures/column.dart          ← DELETE (typedef aliases replaces)
lib/design_system/structures/row.dart             ← DELETE (typedef aliases replaces)
lib/design_system/structures/group.dart           ← DELETE (typedef aliases replaces)
lib/app/bootstrap.dart (or equivalent)            ← register ThemeService manually
```

### Files modified in `quanitya_flutter/`

```
pubspec.yaml                                      ← add qtpi_ui path dep
lib/design_system/qtpi_aliases.dart               ← CREATE: typedef aliases
lib/design_system/theme/theme_service.dart        ← REPLACE body: re-export from qtpi_ui, remove @singleton
lib/design_system/primitives/ui_scaler.dart       ← DELETE
lib/design_system/primitives/app_sizes.dart       ← DELETE
lib/design_system/primitives/app_spacings.dart    ← DELETE
lib/design_system/structures/column.dart          ← DELETE
lib/design_system/structures/row.dart             ← DELETE
lib/design_system/structures/group.dart           ← DELETE
lib/app/bootstrap.dart (or equivalent)            ← register ThemeService manually
```

---

## Task 1: Scaffold `qtpi_ui` as a Flutter package

**Context:** The repo at `/Users/aicoder/Documents/qtpi_ui` already exists with a `docs/` folder and `README.md` on branch `feat/project-1-extraction`. It has NO `pubspec.yaml` and NO `lib/` yet. This task creates the package scaffold.

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/qtpi_ui.dart` (barrel — empty exports for now, filled in later tasks)
- Create: `test/.gitkeep` (so the test dir exists)
- Create: `.gitignore` (standard Flutter .gitignore)
- Create: `analysis_options.yaml` (inherit Flutter's lints)

**Interfaces:**
- Produces: A valid Flutter package that `flutter pub get` and `flutter analyze` can run against. The barrel `package:qtpi_ui/qtpi_ui.dart` exists (empty or minimal).

- [ ] **Step 1: Create `pubspec.yaml`**

  Write `/Users/aicoder/Documents/qtpi_ui/pubspec.yaml`:
  ```yaml
  name: qtpi_ui
  description: Shared design system bones for qtpi apps.
  version: 0.1.0

  environment:
    sdk: '>=3.0.0 <4.0.0'
    flutter: '>=3.0.0'

  dependencies:
    flutter:
      sdk: flutter
    flutter_color_palette:
      git:
        url: https://github.com/qtpi-bonding-org/flutter_color_palette.git
        ref: e8755f5993cb66c6dfd4696df87bf6ef64229756

  dev_dependencies:
    flutter_test:
      sdk: flutter
    flutter_lints: ^5.0.0

  flutter:
    uses-material-design: true
  ```

- [ ] **Step 2: Create `lib/qtpi_ui.dart` barrel (empty for now)**

  Write `/Users/aicoder/Documents/qtpi_ui/lib/qtpi_ui.dart`:
  ```dart
  library qtpi_ui;
  
  // Primitives
  export 'src/primitives/ui_scaler.dart';
  export 'src/primitives/app_sizes.dart';
  export 'src/primitives/app_spacings.dart';
  
  // Structures
  export 'src/structures/ds_column.dart';
  export 'src/structures/ds_row.dart';
  export 'src/structures/ds_group.dart';
  
  // Theme
  export 'src/theme/theme_service.dart';
  ```

  (These files don't exist yet — the `export` lines will cause errors until later tasks create them. That's fine; the barrel is written once here and not changed again.)

- [ ] **Step 3: Create `.gitignore`**

  Write `/Users/aicoder/Documents/qtpi_ui/.gitignore`:
  ```
  # Dart/Flutter
  .dart_tool/
  .flutter-plugins
  .flutter-plugins-dependencies
  .packages
  build/
  pubspec.lock
  
  # IDE
  .idea/
  .vscode/
  *.iml
  
  # SDD scratch
  .superpowers/sdd/
  ```

- [ ] **Step 4: Create `analysis_options.yaml`**

  Write `/Users/aicoder/Documents/qtpi_ui/analysis_options.yaml`:
  ```yaml
  include: package:flutter_lints/flutter.yaml
  
  linter:
    rules:
      avoid_print: true
      prefer_const_constructors: true
  ```

- [ ] **Step 5: Create `lib/src/` directory structure**

  Run:
  ```bash
  mkdir -p /Users/aicoder/Documents/qtpi_ui/lib/src/primitives
  mkdir -p /Users/aicoder/Documents/qtpi_ui/lib/src/structures
  mkdir -p /Users/aicoder/Documents/qtpi_ui/lib/src/theme
  mkdir -p /Users/aicoder/Documents/qtpi_ui/test/primitives
  mkdir -p /Users/aicoder/Documents/qtpi_ui/test/structures
  mkdir -p /Users/aicoder/Documents/qtpi_ui/test/theme
  ```

- [ ] **Step 6: Run `flutter pub get` and verify it resolves**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui && flutter pub get
  ```
  Expected: `flutter_color_palette` resolves to commit `e8755f5`. No errors.

- [ ] **Step 7: Commit**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui
  git add pubspec.yaml lib/qtpi_ui.dart .gitignore analysis_options.yaml
  git commit -m "feat: scaffold qtpi_ui Flutter package"
  ```

---

## Task 2: Extract token primitives into `qtpi_ui`

**Context:** This task moves the three primitive files from episutra's design system into `qtpi_ui`. They are byte-for-byte identical in both apps (only import paths differ); we take episutra's version as the source of truth. The files are stateless token classes — no DI, no app-specific imports. `app_spacings.dart` is copied verbatim (it imports only `app_sizes.dart` and `flutter`). `app_sizes.dart` imports `ui_scaler.dart`. All imports become relative within the package.

**Source files to copy content from:**
- `/Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/primitives/ui_scaler.dart`
- `/Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/primitives/app_sizes.dart`
- `/Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/primitives/app_spacings.dart`

**Files:**
- Create: `lib/src/primitives/ui_scaler.dart`
- Create: `lib/src/primitives/app_sizes.dart`
- Create: `lib/src/primitives/app_spacings.dart`
- Create: `test/primitives/ui_scaler_test.dart`
- Create: `test/primitives/app_sizes_test.dart`
- Create: `test/primitives/app_spacings_test.dart`

**Interfaces:**
- Produces: `UiScaler`, `AppSizes`, `AppPadding`, `VSpace`, `HSpace` — all with identical public APIs to the originals. Import path: `package:qtpi_ui/qtpi_ui.dart`.

- [ ] **Step 1: Write failing tests for UiScaler**

  Write `test/primitives/ui_scaler_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:qtpi_ui/qtpi_ui.dart';
  
  void main() {
    group('UiScaler', () {
      test('returns unscaled value before init', () {
        expect(UiScaler.instance.px(100), 100.0);
        expect(UiScaler.instance.sp(16), 16.0);
      });
  
      testWidgets('clamps scale factor between 0.85 and 1.15', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) {
              UiScaler.instance.init(context);
              return child!;
            },
            home: Builder(builder: (context) {
              final factor = UiScaler.instance.scaleFactor;
              expect(factor, greaterThanOrEqualTo(0.85));
              expect(factor, lessThanOrEqualTo(1.15));
              return const SizedBox();
            }),
          ),
        );
      });
  
      test('px returns 0 for 0 input', () {
        expect(UiScaler.instance.px(0), 0.0);
      });
    });
  }
  ```

- [ ] **Step 2: Run test to confirm it fails (file missing)**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui && flutter test test/primitives/ui_scaler_test.dart
  ```
  Expected: compile error — `UiScaler` not found.

- [ ] **Step 3: Create `lib/src/primitives/ui_scaler.dart`**

  Copy content verbatim from `/Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/primitives/ui_scaler.dart`. No import changes needed (only imports `flutter/material.dart`).

- [ ] **Step 4: Write failing tests for AppSizes**

  Write `test/primitives/app_sizes_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:qtpi_ui/qtpi_ui.dart';
  
  void main() {
    group('AppSizes', () {
      test('space is based on 8dp grid', () {
        // Before UiScaler init, scale=1.0, so space = 8.0
        expect(AppSizes.space, 8.0);
      });
  
      test('buttonHeight is 6x space', () {
        expect(AppSizes.buttonHeight, AppSizes.space * 6);
      });
  
      test('radiusSmall equals one space unit', () {
        expect(AppSizes.radiusSmall, AppSizes.space);
      });
  
      test('opacityDisabled is 0.38', () {
        expect(AppSizes.opacityDisabled, 0.38);
      });
  
      test('iconSizes are proportional', () {
        expect(AppSizes.iconSmall, lessThan(AppSizes.iconMedium));
        expect(AppSizes.iconMedium, lessThan(AppSizes.iconLarge));
      });
    });
  }
  ```

- [ ] **Step 5: Create `lib/src/primitives/app_sizes.dart`**

  Copy content from episutra's `app_sizes.dart`. Change the import at the top:
  - Old: `import 'ui_scaler.dart';`
  - New: `import 'ui_scaler.dart';` ← same relative path, no change needed.

- [ ] **Step 6: Write failing tests for AppPadding / VSpace / HSpace**

  Write `test/primitives/app_spacings_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:qtpi_ui/qtpi_ui.dart';
  
  void main() {
    group('VSpace', () {
      testWidgets('x1 renders a SizedBox with height == AppSizes.space', (tester) async {
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: VSpace.x1)));
        final box = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(box.height, AppSizes.space);
      });
  
      testWidgets('x2 is double x1', (tester) async {
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: VSpace.x2)));
        final box = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(box.height, AppSizes.space * 2);
      });
    });
  
    group('HSpace', () {
      testWidgets('x1 renders a SizedBox with width == AppSizes.space', (tester) async {
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: HSpace.x1)));
        final box = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(box.width, AppSizes.space);
      });
    });
  
    group('AppPadding', () {
      test('allSingle uses one space unit', () {
        expect(AppPadding.allSingle.left, AppSizes.space);
        expect(AppPadding.allSingle.top, AppSizes.space);
      });
  
      test('horizontalDouble uses 2x space', () {
        expect(AppPadding.horizontalDouble.left, AppSizes.space * 2);
        expect(AppPadding.horizontalDouble.top, 0.0);
      });
    });
  }
  ```

- [ ] **Step 7: Create `lib/src/primitives/app_spacings.dart`**

  Copy content from episutra's `app_spacings.dart`. Update import at top:
  - Old: `import 'app_sizes.dart';`
  - New: `import 'app_sizes.dart';` ← same relative, no change.
  - Remove `import 'package:flutter/material.dart';` only if it wasn't there — it IS there, keep it.

- [ ] **Step 8: Run all primitive tests**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui && flutter test test/primitives/
  ```
  Expected: all pass. If `VSpace`/`HSpace` use `const VSpace._()` constructors, the widget test may need `find.byType(SizedBox)` — adjust selector if needed.

- [ ] **Step 9: Run flutter analyze**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui && flutter analyze
  ```
  Expected: zero errors (warnings about barrel re-exports for missing files are OK at this stage if the analyze is run on `lib/src/` only — but the barrel at `lib/qtpi_ui.dart` exports files that don't exist yet, so run analyze scoped to what exists or accept the "file not found" export warnings as temporary).

  Actually, to avoid barrel export errors, do NOT run `flutter analyze` on the full package until Task 4 is done. Instead, run it scoped: `flutter analyze lib/src/primitives/`.

- [ ] **Step 10: Commit**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui
  git add lib/src/primitives/ test/primitives/
  git commit -m "feat(primitives): extract UiScaler, AppSizes, AppPadding/VSpace/HSpace"
  ```

---

## Task 3: Extract structure widgets into `qtpi_ui`

**Context:** This task creates `DsColumn`, `DsRow`, `DsGroup` in `qtpi_ui`. These are the renamed structure primitives. Key differences vs the originals:

- **`DsColumn`** adds a `mainAxisSize` parameter that quanitya's `QuanityaColumn` has but episutra's `EpisutraColumn` lacks. Default: `MainAxisSize.max` (matches quanitya). Episutra's existing call sites will still compile because they don't pass `mainAxisSize` — it defaults.
- **`DsRow`** is copied verbatim from episutra's `EpisutraRow` (quanitya's is identical). Rename only.
- **`DsGroup`** is a clean re-implementation using Flutter's `InkWell` (NOT `GlowTap` — `GlowTap` is an episutra-specific widget). It includes an optional `testId` param (String, nullable, for semantics testing) that quanitya's `QuanityaGroup` doesn't have — this is backward-compat since it's optional. Palette access: `DsGroup` accepts an optional `interactableColor` parameter (a `Color`) rather than reading from a palette directly.

**Source files to read:**
- `/Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/structures/column.dart`
- `/Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/structures/row.dart`
- `/Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/structures/group.dart`
- `/Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter/lib/design_system/structures/group.dart`

**Files:**
- Create: `lib/src/structures/ds_column.dart`
- Create: `lib/src/structures/ds_row.dart`
- Create: `lib/src/structures/ds_group.dart`
- Create: `test/structures/ds_column_test.dart`
- Create: `test/structures/ds_row_test.dart`
- Create: `test/structures/ds_group_test.dart`

**Interfaces:**
- Produces:
  - `DsColumn({required List<Widget> children, CrossAxisAlignment crossAlignment, MainAxisAlignment mainAlignment, MainAxisSize mainAxisSize, Widget? spacing})`
  - `DsRow({Widget? start, Widget? middle, Widget? end, CrossAxisAlignment alignment, Widget? spacing})`
  - `DsGroup({required Widget child, required String testId, VoidCallback? onTap, EdgeInsets? padding, bool showChevron, Color? chevronColor})`

- [ ] **Step 1: Write failing tests for DsColumn**

  Write `test/structures/ds_column_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:qtpi_ui/qtpi_ui.dart';
  
  void main() {
    group('DsColumn', () {
      testWidgets('renders single child without spacing', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsColumn(children: [const Text('only')])),
        ));
        expect(find.text('only'), findsOneWidget);
        expect(find.byType(VSpace), findsNothing);
      });
  
      testWidgets('interleaves VSpace.x1 between children by default', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsColumn(children: [
            const Text('a'), const Text('b'), const Text('c'),
          ])),
        ));
        expect(find.byType(VSpace), findsNWidgets(2));
      });
  
      testWidgets('uses custom spacing widget when provided', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsColumn(
            spacing: VSpace.x3,
            children: [const Text('a'), const Text('b')],
          )),
        ));
        final spacer = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(spacer.height, AppSizes.space * 3);
      });
  
      testWidgets('respects mainAxisSize parameter', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsColumn(
            mainAxisSize: MainAxisSize.min,
            children: [const Text('a')],
          )),
        ));
        final col = tester.widget<Column>(find.byType(Column).first);
        expect(col.mainAxisSize, MainAxisSize.min);
      });
    });
  }
  ```

- [ ] **Step 2: Run test to verify it fails**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui && flutter test test/structures/ds_column_test.dart
  ```
  Expected: compile error — `DsColumn` not found.

- [ ] **Step 3: Create `lib/src/structures/ds_column.dart`**

  Write `/Users/aicoder/Documents/qtpi_ui/lib/src/structures/ds_column.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../primitives/app_spacings.dart';
  
  class DsColumn extends StatelessWidget {
    final List<Widget> children;
    final CrossAxisAlignment crossAlignment;
    final MainAxisAlignment mainAlignment;
    final MainAxisSize mainAxisSize;
    final Widget? spacing;
  
    const DsColumn({
      super.key,
      required this.children,
      this.crossAlignment = CrossAxisAlignment.start,
      this.mainAlignment = MainAxisAlignment.start,
      this.mainAxisSize = MainAxisSize.max,
      this.spacing,
    });
  
    Widget get _defaultSpacing => VSpace.x1;
  
    @override
    Widget build(BuildContext context) {
      if (children.length <= 1) {
        return Column(
          crossAxisAlignment: crossAlignment,
          mainAxisAlignment: mainAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        );
      }
  
      final spacedChildren = <Widget>[];
      final actualSpacing = spacing ?? _defaultSpacing;
      for (var i = 0; i < children.length; i++) {
        spacedChildren.add(children[i]);
        if (i != children.length - 1) spacedChildren.add(actualSpacing);
      }
  
      return Column(
        crossAxisAlignment: crossAlignment,
        mainAxisAlignment: mainAlignment,
        mainAxisSize: mainAxisSize,
        children: spacedChildren,
      );
    }
  }
  ```

- [ ] **Step 4: Write failing tests for DsRow**

  Write `test/structures/ds_row_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:qtpi_ui/qtpi_ui.dart';
  
  void main() {
    group('DsRow', () {
      testWidgets('middle slot is expanded', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsRow(middle: const Text('mid'))),
        ));
        expect(find.byType(Expanded), findsOneWidget);
      });
  
      testWidgets('no middle renders Spacer', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsRow(
            start: const Text('s'),
            end: const Text('e'),
          )),
        ));
        expect(find.byType(Spacer), findsOneWidget);
      });
  
      testWidgets('renders start and end alongside middle', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsRow(
            start: const Text('s'),
            middle: const Text('mid'),
            end: const Text('e'),
          )),
        ));
        expect(find.text('s'), findsOneWidget);
        expect(find.text('mid'), findsOneWidget);
        expect(find.text('e'), findsOneWidget);
      });
    });
  }
  ```

- [ ] **Step 5: Create `lib/src/structures/ds_row.dart`**

  Write `/Users/aicoder/Documents/qtpi_ui/lib/src/structures/ds_row.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../primitives/app_spacings.dart';
  
  class DsRow extends StatelessWidget {
    final Widget? start;
    final Widget? middle;
    final Widget? end;
    final CrossAxisAlignment alignment;
    final Widget? spacing;
  
    const DsRow({
      super.key,
      this.start,
      this.middle,
      this.end,
      this.alignment = CrossAxisAlignment.start,
      this.spacing,
    });
  
    Widget get _defaultSpacing => HSpace.x2;
  
    @override
    Widget build(BuildContext context) {
      final actualSpacing = spacing ?? _defaultSpacing;
      return Row(
        crossAxisAlignment: alignment,
        children: [
          if (start != null) ...[start!, actualSpacing],
          if (middle != null) Expanded(child: middle!) else const Spacer(),
          if (end != null) ...[actualSpacing, end!],
        ],
      );
    }
  }
  ```

- [ ] **Step 6: Write failing tests for DsGroup**

  Write `test/structures/ds_group_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:qtpi_ui/qtpi_ui.dart';
  
  void main() {
    group('DsGroup', () {
      testWidgets('non-tappable renders plain Padding', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsGroup(
            testId: 'test-group',
            child: const Text('content'),
          )),
        ));
        expect(find.byType(InkWell), findsNothing);
        expect(find.text('content'), findsOneWidget);
      });
  
      testWidgets('tappable renders InkWell and fires onTap', (tester) async {
        var tapped = false;
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsGroup(
            testId: 'tap-group',
            onTap: () => tapped = true,
            child: const Text('tap me'),
          )),
        ));
        expect(find.byType(InkWell), findsOneWidget);
        await tester.tap(find.byType(InkWell));
        expect(tapped, isTrue);
      });
  
      testWidgets('showChevron renders chevron_right icon when tappable', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsGroup(
            testId: 'chevron-group',
            onTap: () {},
            showChevron: true,
            child: const Text('nav'),
          )),
        ));
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });
  
      testWidgets('showChevron is false by default', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: DsGroup(
            testId: 'no-chevron',
            onTap: () {},
            child: const Text('tap'),
          )),
        ));
        expect(find.byIcon(Icons.chevron_right), findsNothing);
      });
    });
  }
  ```

- [ ] **Step 7: Create `lib/src/structures/ds_group.dart`**

  Write `/Users/aicoder/Documents/qtpi_ui/lib/src/structures/ds_group.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../primitives/app_spacings.dart';
  import '../primitives/app_sizes.dart';
  
  class DsGroup extends StatelessWidget {
    final Widget child;
    final VoidCallback? onTap;
    final EdgeInsets? padding;
    final bool showChevron;
    final Color? chevronColor;
    final String testId;
  
    const DsGroup({
      super.key,
      required this.child,
      required this.testId,
      this.onTap,
      this.padding,
      this.showChevron = false,
      this.chevronColor,
    });
  
    @override
    Widget build(BuildContext context) {
      final effectivePadding = padding ?? AppPadding.listItem;
      final effectiveChevronColor = chevronColor ?? Theme.of(context).colorScheme.primary;
  
      if (onTap != null) {
        return Semantics(
          button: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            child: Padding(
              padding: effectivePadding,
              child: showChevron
                  ? Row(children: [
                      Expanded(child: child),
                      HSpace.x1,
                      ExcludeSemantics(
                        child: Icon(
                          Icons.chevron_right,
                          size: AppSizes.size20,
                          color: effectiveChevronColor,
                        ),
                      ),
                    ])
                  : child,
            ),
          ),
        );
      }
  
      return Padding(padding: effectivePadding, child: child);
    }
  }
  ```

- [ ] **Step 8: Run all structure tests**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui && flutter test test/structures/
  ```
  Expected: all pass.

- [ ] **Step 9: Commit**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui
  git add lib/src/structures/ test/structures/
  git commit -m "feat(structures): add DsColumn, DsRow, DsGroup"
  ```

---

## Task 4: Extract ThemeService into `qtpi_ui`

**Context:** The shared `ThemeService` differs from both apps' versions:
1. No `@singleton` annotation, no injectable import.
2. Constructor takes `lightPalette` (required) and optional `darkPalette`. If `darkPalette` is null, `currentPalette` always returns `lightPalette` (episutra's behavior — dark-only app).
3. Adds `_overrides: Map<String, Color>` for Storybook live editing (empty in production).
4. `currentPalette` merges base palette colors with overrides using `AppColorPalette(colors: {...base.colors, ..._overrides})`.

**Important — `IColorPalette` interface** (from `flutter_color_palette` package):
```dart
abstract class IColorPalette {
  Map<String, Color> get colors;
  Color? getColor(String identifier);
  List<String> get colorIdentifiers;
  IColorPalette get symmetricPalette;
  String? get name;
  String? get description;
  List<String>? get tags;
}
```

`AppColorPalette` is the concrete class: `AppColorPalette({required Map<String, Color> colors, String? name, ...})`.

The override mechanism: when `_overrides` is non-empty, `currentPalette` returns `AppColorPalette(colors: {...base.colors, ..._overrides}, name: base.name)`. This spreads overrides on top of the base map — any key in `_overrides` wins. When `_overrides` is empty, return the base palette directly (no allocation).

**quanitya note:** quanitya's `ThemeService` also has a `buildAiTheme` method. That method stays in quanitya (it's quanitya-specific). The shared ThemeService does NOT include it. quanitya's `ThemeService` will be re-implemented as a thin subclass or the file will delegate to qtpi_ui's ThemeService (see Task 6).

**Files:**
- Create: `lib/src/theme/theme_service.dart`
- Create: `test/theme/theme_service_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class ThemeService extends ChangeNotifier {
    ThemeService({required IColorPalette lightPalette, IColorPalette? darkPalette});
    IColorPalette get currentPalette;
    bool get isDarkMode;
    void toggleDarkMode();
    void setDarkMode(bool isDark);
    void setOverride(String key, Color value);
    void clearOverrides();
    Map<String, Color> get overrides; // read-only view for storybook
  }
  ```

- [ ] **Step 1: Write failing tests for ThemeService**

  Write `test/theme/theme_service_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_color_palette/flutter_color_palette.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:qtpi_ui/qtpi_ui.dart';
  
  AppColorPalette _palette(String name, Color fill) => AppColorPalette(
    colors: {'color1': fill, 'accent': const Color(0xFF00C3FF)},
    name: name,
  );
  
  void main() {
    group('ThemeService', () {
      test('returns lightPalette when not dark mode', () {
        final light = _palette('light', const Color(0xFFFFFFFF));
        final svc = ThemeService(lightPalette: light);
        expect(svc.currentPalette.name, 'light');
      });
  
      test('returns lightPalette when darkPalette is null and dark mode toggled', () {
        final light = _palette('light', const Color(0xFFFFFFFF));
        final svc = ThemeService(lightPalette: light)..toggleDarkMode();
        expect(svc.currentPalette.name, 'light');
      });
  
      test('returns darkPalette when dark mode set and darkPalette provided', () {
        final light = _palette('light', const Color(0xFFFFFFFF));
        final dark = _palette('dark', const Color(0xFF000000));
        final svc = ThemeService(lightPalette: light, darkPalette: dark)..setDarkMode(true);
        expect(svc.currentPalette.name, 'dark');
      });
  
      test('notifies listeners on toggleDarkMode', () {
        final svc = ThemeService(lightPalette: _palette('p', Colors.white));
        var notified = false;
        svc.addListener(() => notified = true);
        svc.toggleDarkMode();
        expect(notified, isTrue);
      });
  
      test('setDarkMode does not notify when value unchanged', () {
        final svc = ThemeService(lightPalette: _palette('p', Colors.white));
        var count = 0;
        svc.addListener(() => count++);
        svc.setDarkMode(false); // already false
        expect(count, 0);
      });
  
      test('setOverride merges into current palette', () {
        const overrideKey = 'color1';
        const newColor = Color(0xFFABCDEF);
        final svc = ThemeService(lightPalette: _palette('p', Colors.white));
        svc.setOverride(overrideKey, newColor);
        expect(svc.currentPalette.getColor(overrideKey), newColor);
      });
  
      test('setOverride notifies listeners', () {
        final svc = ThemeService(lightPalette: _palette('p', Colors.white));
        var notified = false;
        svc.addListener(() => notified = true);
        svc.setOverride('color1', Colors.red);
        expect(notified, isTrue);
      });
  
      test('clearOverrides restores base palette color', () {
        const original = Color(0xFFFFFFFF);
        final svc = ThemeService(lightPalette: _palette('p', original));
        svc.setOverride('color1', Colors.red);
        svc.clearOverrides();
        expect(svc.currentPalette.getColor('color1'), original);
      });
  
      test('overrides getter returns current override map', () {
        final svc = ThemeService(lightPalette: _palette('p', Colors.white));
        svc.setOverride('accent', Colors.blue);
        expect(svc.overrides['accent'], Colors.blue);
      });
    });
  }
  ```

- [ ] **Step 2: Run test to verify it fails**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui && flutter test test/theme/theme_service_test.dart
  ```
  Expected: compile error — `ThemeService` not found.

- [ ] **Step 3: Create `lib/src/theme/theme_service.dart`**

  Write `/Users/aicoder/Documents/qtpi_ui/lib/src/theme/theme_service.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_color_palette/flutter_color_palette.dart';
  
  class ThemeService extends ChangeNotifier {
    ThemeService({required IColorPalette lightPalette, IColorPalette? darkPalette})
        : _lightPalette = lightPalette,
          _darkPalette = darkPalette;
  
    final IColorPalette _lightPalette;
    final IColorPalette? _darkPalette;
    bool _isDarkMode = false;
    final Map<String, Color> _overrides = {};
  
    bool get isDarkMode => _isDarkMode;
  
    Map<String, Color> get overrides => Map.unmodifiable(_overrides);
  
    IColorPalette get currentPalette {
      final base = _isDarkMode ? (_darkPalette ?? _lightPalette) : _lightPalette;
      if (_overrides.isEmpty) return base;
      return AppColorPalette(
        colors: {...base.colors, ..._overrides},
        name: base.name,
      );
    }
  
    void toggleDarkMode() {
      _isDarkMode = !_isDarkMode;
      notifyListeners();
    }
  
    void setDarkMode(bool isDark) {
      if (_isDarkMode == isDark) return;
      _isDarkMode = isDark;
      notifyListeners();
    }
  
    void setOverride(String key, Color value) {
      _overrides[key] = value;
      notifyListeners();
    }
  
    void clearOverrides() {
      _overrides.clear();
      notifyListeners();
    }
  }
  ```

- [ ] **Step 4: Run all tests**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui && flutter test test/theme/
  ```
  Expected: all 9 tests pass.

- [ ] **Step 5: Run full flutter analyze**

  All source files now exist, so the barrel no longer has missing exports.
  ```bash
  cd /Users/aicoder/Documents/qtpi_ui && flutter analyze
  ```
  Expected: zero errors.

- [ ] **Step 6: Run full test suite to confirm nothing broken**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui && flutter test
  ```
  Expected: all tests pass.

- [ ] **Step 7: Commit**

  ```bash
  cd /Users/aicoder/Documents/qtpi_ui
  git add lib/src/theme/ test/theme/
  git commit -m "feat(theme): add ThemeService with palette injection and override map"
  ```

---

## Task 5: Migrate episutra to consume `qtpi_ui`

**Context:** This task updates `episutra_flutter` to use the package created in Tasks 1-4. Work happens in `/Users/aicoder/Documents/episutra/app/episutra_flutter`. The git branch for episutra is `main` (or whatever episutra's current branch is — do NOT create a new branch in episutra; commit to the current branch). Steps:

1. Add `qtpi_ui` path dep + pin `flutter_color_palette` in pubspec.yaml
2. Create `lib/design_system/qtpi_aliases.dart` with typedef aliases
3. Delete the three primitive files and three structure files (moved to qtpi_ui)
4. Update `lib/design_system/theme/theme_service.dart` to use qtpi_ui's ThemeService (no @singleton)
5. Find where ThemeService is registered in DI and replace with manual `getIt.registerSingleton(ThemeService(lightPalette: EpisutraPalette.primary))`
6. Fix all imports across the design system that pointed to the deleted files
7. `flutter analyze` must pass with zero errors

**Key facts about episutra's codebase:**
- DI framework: `injectable` v3 + `get_it` v9
- `context.colors` is defined in `lib/support/extensions/context_extensions.dart` and calls `GetIt.instance<ThemeService>().currentPalette`
- `EpisutraPalette.primary` and `EpisutraPalette.dark` are the light/dark palettes
- `app_theme.dart` stays in episutra — it uses `EpisutraFonts` which stay per-app
- The barrel `lib/design_system/design_system.dart` currently only exports `theme/app_theme.dart` — it does NOT need to export qtpi_ui things (that's the app's job)
- The generated file `lib/app/bootstrap.config.dart` is auto-generated by injectable. After removing `@singleton` from ThemeService, the next build_runner run will drop ThemeService from the generated config. We add a manual registration BEFORE calling the generated `configureDependencies()` or `$initGetIt()`.

**How to find the bootstrap file:** grep for `configureDependencies` or `$initGetIt` in `lib/app/`. The file that calls it is where manual registration goes.

**Important:** Do NOT run `flutter pub run build_runner build` in this task — the generated `bootstrap.config.dart` is managed by episutra's own dev cycle. Simply removing `@singleton` from `ThemeService` is sufficient; the stale generated file will still work (it just has a now-removed registration for ThemeService, which is harmless — `get_it` allows double registration only if you reset, but since we're adding manual registration BEFORE the generated init, and injectable v3's generated code registers via `gh.singleton(() => ThemeService())`, we'll have a conflict). 

**Therefore:** Instead of removing `@singleton` and re-running codegen, take this approach:
- Episutra's `lib/design_system/theme/theme_service.dart` becomes a shim that re-exports from qtpi_ui:
  ```dart
  import 'package:qtpi_ui/qtpi_ui.dart';
  export 'package:qtpi_ui/qtpi_ui.dart' show ThemeService;
  ```
  But this still has `@singleton` in the generated config pointing to the shim. To avoid re-running codegen, simply keep the `@singleton` annotation on the shim class that subclasses qtpi_ui's ThemeService:
  
  ```dart
  // lib/design_system/theme/theme_service.dart
  import 'package:injectable/injectable.dart';
  import 'package:qtpi_ui/qtpi_ui.dart';
  import '../primitives/episutra_palette.dart';
  
  @singleton
  class ThemeService extends QtpiThemeService {
    ThemeService() : super(
      lightPalette: EpisutraPalette.primary,
      darkPalette: EpisutraPalette.dark,
    );
  }
  ```

  **BUT:** This requires renaming the qtpi_ui ThemeService to `QtpiThemeService` to avoid a name collision. That's a disruptive change to the qtpi_ui public API and all future consumers. 

  **Better approach:** Keep the episutra `ThemeService` as a local class in episutra's DI (via `@singleton`) but make it delegate to an instance of the qtpi_ui `ThemeService` stored as a field. No — this is complex.

  **Cleanest approach:** Import qtpi_ui's ThemeService with a prefix:
  ```dart
  // lib/design_system/theme/theme_service.dart (episutra — remains in place)
  import 'package:injectable/injectable.dart';
  import 'package:flutter_color_palette/flutter_color_palette.dart';
  import 'package:qtpi_ui/qtpi_ui.dart' as qtpi;
  import '../primitives/episutra_palette.dart';
  
  @singleton
  class ThemeService extends qtpi.ThemeService {
    ThemeService() : super(
      lightPalette: EpisutraPalette.primary,
      darkPalette: EpisutraPalette.dark,
    );
  }
  ```
  
  This works! The episutra `ThemeService` IS the qtpi_ui `ThemeService` (via inheritance), keeps `@singleton` for injectable, gets DI-registered automatically by the existing generated code, and call sites at `GetIt.instance<ThemeService>()` still resolve the episutra subclass (which IS a `ThemeService`). This is the cleanest zero-codegen-rerun migration path.

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/design_system/qtpi_aliases.dart`
- Modify: `lib/design_system/theme/theme_service.dart` (becomes thin subclass)
- Delete: `lib/design_system/primitives/ui_scaler.dart`
- Delete: `lib/design_system/primitives/app_sizes.dart`
- Delete: `lib/design_system/primitives/app_spacings.dart`
- Delete: `lib/design_system/structures/column.dart`
- Delete: `lib/design_system/structures/row.dart`
- Delete: `lib/design_system/structures/group.dart`
- Modify: any files that imported the deleted files (update to `package:qtpi_ui/qtpi_ui.dart`)

**Interfaces:**
- Consumes: `qtpi_ui` (Tasks 1-4)
- Produces: episutra builds and analyzes clean; `EpisutraColumn`, `EpisutraRow`, `EpisutraGroup`, `UiScaler`, `AppSizes`, `VSpace`, `HSpace`, `AppPadding`, `ThemeService` all still work at call sites without any rename.

- [ ] **Step 1: Update `pubspec.yaml`**

  In `/Users/aicoder/Documents/episutra/app/episutra_flutter/pubspec.yaml`, make two changes:

  a) Add `qtpi_ui` dependency (after the existing `flutter_color_palette` entry or anywhere in `dependencies`):
  ```yaml
  qtpi_ui:
    path: ../../../qtpi_ui
  ```

  b) Change the existing `flutter_color_palette` entry from:
  ```yaml
  flutter_color_palette:
    git: git@github.com:qtpi-bonding-org/flutter_color_palette.git
  ```
  To:
  ```yaml
  flutter_color_palette:
    git:
      url: https://github.com/qtpi-bonding-org/flutter_color_palette.git
      ref: e8755f5993cb66c6dfd4696df87bf6ef64229756
  ```

- [ ] **Step 2: Run `flutter pub get` and verify it resolves**

  ```bash
  cd /Users/aicoder/Documents/episutra/app/episutra_flutter && flutter pub get
  ```
  Expected: resolves without conflicts. `qtpi_ui` and `flutter_color_palette` should both resolve. If there's a git source conflict on `flutter_color_palette` (episutra's now-pinned HTTPS vs qtpi_ui's HTTPS), they should now match — both HTTPS + same ref. Fix any remaining discrepancy before proceeding.

- [ ] **Step 3: Create `lib/design_system/qtpi_aliases.dart`**

  Write `/Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/qtpi_aliases.dart`:
  ```dart
  export 'package:qtpi_ui/qtpi_ui.dart';
  
  typedef EpisutraColumn = DsColumn;
  typedef EpisutraRow = DsRow;
  typedef EpisutraGroup = DsGroup;
  ```

  Note: the `export 'package:qtpi_ui/qtpi_ui.dart'` re-exports everything (UiScaler, AppSizes, VSpace, HSpace, AppPadding, ThemeService, DsColumn, DsRow, DsGroup). Files that previously imported the individual primitive files can now import this one aliases file instead.

- [ ] **Step 4: Update `lib/design_system/theme/theme_service.dart`**

  Replace the entire file content with:
  ```dart
  import 'package:injectable/injectable.dart';
  import 'package:qtpi_ui/qtpi_ui.dart' as qtpi;
  import 'primitives/episutra_palette.dart';
  
  @singleton
  class ThemeService extends qtpi.ThemeService {
    ThemeService() : super(
      lightPalette: EpisutraPalette.primary,
      darkPalette: EpisutraPalette.dark,
    );
  }
  ```

  **Important:** The import path for `episutra_palette.dart` must be correct relative to this file's location (`lib/design_system/theme/`). The palette is at `lib/design_system/primitives/episutra_palette.dart`, so relative path is `../primitives/episutra_palette.dart`. Not `primitives/episutra_palette.dart`.

  Fix the import:
  ```dart
  import '../primitives/episutra_palette.dart';
  ```

- [ ] **Step 5: Delete the moved primitive files**

  ```bash
  rm /Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/primitives/ui_scaler.dart
  rm /Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/primitives/app_sizes.dart
  rm /Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/primitives/app_spacings.dart
  ```

- [ ] **Step 6: Delete the moved structure files**

  ```bash
  rm /Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/structures/column.dart
  rm /Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/structures/row.dart
  rm /Users/aicoder/Documents/episutra/app/episutra_flutter/lib/design_system/structures/group.dart
  ```

- [ ] **Step 7: Find all files with broken imports and fix them**

  Run:
  ```bash
  cd /Users/aicoder/Documents/episutra/app/episutra_flutter && flutter analyze 2>&1 | grep "error\|Error" | head -40
  ```

  For each file with an import error pointing to a deleted file, replace its import with:
  ```dart
  import 'package:qtpi_ui/qtpi_ui.dart';
  ```
  (or a relative import to `qtpi_aliases.dart` if the file is inside `lib/design_system/`)

  Files that typically need updating:
  - Any file importing `../primitives/ui_scaler.dart`, `../primitives/app_sizes.dart`, `../primitives/app_spacings.dart`
  - Any file importing `../structures/column.dart`, `../structures/row.dart`, `../structures/group.dart`
  - `lib/design_system/structures/group.dart` is deleted but it imported `widgets/glow_tap.dart` — the `EpisutraGroup` typedef now points to `DsGroup` which uses InkWell, so the import chain is broken at the source. Files that used `EpisutraGroup` will now get `DsGroup` via the typedef, which uses InkWell. This is correct behavior; no call sites change.

  Also check `lib/design_system/theme/app_theme.dart` — it imports `episutra_fonts.dart` and `episutra_palette.dart` (both stay) but also `app_sizes.dart` (now gone). Fix its app_sizes import to `package:qtpi_ui/qtpi_ui.dart`.

- [ ] **Step 8: Run `flutter analyze` and verify zero errors**

  ```bash
  cd /Users/aicoder/Documents/episutra/app/episutra_flutter && flutter analyze
  ```
  Expected: zero errors. Fix any remaining import errors before proceeding.

- [ ] **Step 9: Commit episutra migration**

  ```bash
  cd /Users/aicoder/Documents/episutra
  git add app/episutra_flutter/pubspec.yaml \
          app/episutra_flutter/lib/design_system/ \
          app/episutra_flutter/pubspec.lock
  git commit -m "feat(deps): migrate episutra design system bones to qtpi_ui"
  ```

---

## Task 6: Migrate quanitya to consume `qtpi_ui`

**Context:** Same migration as Task 5, but for quanitya. Work happens in `/Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter`. quanitya is on branch `feat/spm-powersync-quanitya` — commit to that branch.

**Key differences from episutra migration:**
- quanitya's `flutter_color_palette` is ALREADY on HTTPS + `e8755f5` — no pubspec change needed for that entry.
- quanitya's `ThemeService` has an extra `buildAiTheme` method and `_buildTextTheme` helper that are quanitya-specific (used by quanitya's AI theme generation feature). These must be preserved. The subclass approach keeps them: quanitya's `ThemeService` subclasses qtpi_ui's and adds those methods back.
- quanitya uses `injectable` v2 (NOT v3 like episutra). The `@singleton` annotation works the same way in v2/v3 so no change needed.
- quanitya's palette is at `lib/design_system/primitives/quanitya_palette.dart`: `QuanityaPalette.primary` and `QuanityaPalette.dark`.
- `typedef QuanityaColumn = DsColumn`, `typedef QuanityaRow = DsRow`, `typedef QuanityaGroup = DsGroup`.
- quanitya's `QuanityaGroup` uses `InkWell` already (no GlowTap) — the DsGroup is a near-identical replacement.
- quanitya's `QuanityaColumn` has `mainAxisSize` param — `DsColumn` has it too (added in Task 3), so typedef is clean.
- `lib/design_system/theme/app_theme.dart` in quanitya imports `quanitya_fonts.dart` + `app_sizes.dart`. Fix the `app_sizes.dart` import.
- The logic/templates import in quanitya's current `ThemeService` (`import '../../logic/templates/models/engine/page_configuration.dart'`) is needed for `buildAiTheme`'s `FontsConfig` parameter. Keep that import in the quanitya subclass.

**Files:**
- Modify: `pubspec.yaml` (add qtpi_ui path dep only)
- Create: `lib/design_system/qtpi_aliases.dart`
- Modify: `lib/design_system/theme/theme_service.dart` (subclass with buildAiTheme preserved)
- Delete: `lib/design_system/primitives/ui_scaler.dart`
- Delete: `lib/design_system/primitives/app_sizes.dart`
- Delete: `lib/design_system/primitives/app_spacings.dart`
- Delete: `lib/design_system/structures/column.dart`
- Delete: `lib/design_system/structures/row.dart`
- Delete: `lib/design_system/structures/group.dart`
- Modify: any files with broken imports

**Interfaces:**
- Consumes: `qtpi_ui` (Tasks 1-4)
- Produces: quanitya builds and analyzes clean; `QuanityaColumn`, `QuanityaRow`, `QuanityaGroup`, `UiScaler`, `AppSizes`, `VSpace`, `HSpace`, `AppPadding` all still work.

- [ ] **Step 1: Add `qtpi_ui` to `pubspec.yaml`**

  In `/Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter/pubspec.yaml`, add:
  ```yaml
  qtpi_ui:
    path: ../../../../../qtpi_ui
  ```

  **Important: path calculation.** quanitya_flutter is at `…/openops/project/quanitya/public/quanitya_flutter/`. qtpi_ui is at `…/Documents/qtpi_ui/`. The relative path from quanitya_flutter to qtpi_ui is: go up 5 levels (`../../../../../../`) then into `qtpi_ui`. Actually count the path segments:
  - `quanitya_flutter/` → up → `public/` → up → `quanitya/` → up → `project/` → up → `openops/` → up → `Documents/`(same parent as openops) — wait, let me be precise:
  
  ```
  /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter/
  /Users/aicoder/Documents/qtpi_ui/
  ```
  
  From quanitya_flutter: `../../../../../../qtpi_ui` goes:
  - `..` = public/quanitya/project/openops/Documents → NO.
  
  Actually from quanitya_flutter's pubspec.yaml location:
  - `../` = `public/`  
  - `../../` = `quanitya/`
  - `../../../` = `project/`
  - `../../../../` = `openops/`
  - `../../../../../` = `Documents/`
  - `../../../../../qtpi_ui` = `/Users/aicoder/Documents/qtpi_ui` ✓
  
  So the correct path is:
  ```yaml
  qtpi_ui:
    path: ../../../../../qtpi_ui
  ```

- [ ] **Step 2: Run `flutter pub get`**

  ```bash
  cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter pub get
  ```
  Expected: resolves without conflicts.

- [ ] **Step 3: Create `lib/design_system/qtpi_aliases.dart`**

  Write the file:
  ```dart
  export 'package:qtpi_ui/qtpi_ui.dart';
  
  typedef QuanityaColumn = DsColumn;
  typedef QuanityaRow = DsRow;
  typedef QuanityaGroup = DsGroup;
  ```

- [ ] **Step 4: Update `lib/design_system/theme/theme_service.dart`**

  quanitya's ThemeService has `buildAiTheme` and `_buildTextTheme` — preserve them in the subclass. Replace the file with:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:injectable/injectable.dart';
  import 'package:flutter_color_palette/flutter_color_palette.dart';
  import 'package:qtpi_ui/qtpi_ui.dart' as qtpi;
  import '../primitives/quanitya_palette.dart';
  import '../primitives/app_sizes.dart';
  import '../../logic/templates/models/engine/page_configuration.dart';
  
  @singleton
  class ThemeService extends qtpi.ThemeService {
    ThemeService() : super(
      lightPalette: QuanityaPalette.primary,
      darkPalette: QuanityaPalette.dark,
    );
  
    ThemeData buildAiTheme({
      required IColorPalette colorPalette,
      FontsConfig? fonts,
      bool isDark = false,
    }) {
      final brightness = isDark ? Brightness.dark : Brightness.light;
      return ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorPalette.primaryColor,
          brightness: brightness,
          primary: colorPalette.primaryColor,
          secondary: colorPalette.secondaryColor,
          error: colorPalette.destructiveColor,
          surface: colorPalette.backgroundPrimary,
        ),
        textTheme: _buildTextTheme(fonts, brightness),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPalette.primaryColor,
            foregroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: colorPalette.backgroundPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: colorPalette.primaryColor,
          foregroundColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            borderSide: BorderSide(color: colorPalette.textSecondary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            borderSide: BorderSide(color: colorPalette.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            borderSide: BorderSide(color: colorPalette.destructiveColor),
          ),
        ),
      );
    }
  
    TextTheme _buildTextTheme(FontsConfig? fonts, Brightness brightness) {
      final baseTheme = brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme;
      if (fonts == null) return baseTheme;
      return baseTheme.copyWith(
        headlineLarge: baseTheme.headlineLarge?.copyWith(fontFamily: fonts.titleFontFamily, fontWeight: fonts.titleFontWeight),
        headlineMedium: baseTheme.headlineMedium?.copyWith(fontFamily: fonts.titleFontFamily, fontWeight: fonts.titleFontWeight),
        headlineSmall: baseTheme.headlineSmall?.copyWith(fontFamily: fonts.titleFontFamily, fontWeight: fonts.titleFontWeight),
        titleLarge: baseTheme.titleLarge?.copyWith(fontFamily: fonts.subtitleFontFamily, fontWeight: fonts.subtitleFontWeight),
        titleMedium: baseTheme.titleMedium?.copyWith(fontFamily: fonts.subtitleFontFamily, fontWeight: fonts.subtitleFontWeight),
        titleSmall: baseTheme.titleSmall?.copyWith(fontFamily: fonts.subtitleFontFamily, fontWeight: fonts.subtitleFontWeight),
        bodyLarge: baseTheme.bodyLarge?.copyWith(fontFamily: fonts.bodyFontFamily, fontWeight: fonts.bodyFontWeight),
        bodyMedium: baseTheme.bodyMedium?.copyWith(fontFamily: fonts.bodyFontFamily, fontWeight: fonts.bodyFontWeight),
        bodySmall: baseTheme.bodySmall?.copyWith(fontFamily: fonts.bodyFontFamily, fontWeight: fonts.bodyFontWeight),
        labelLarge: baseTheme.labelLarge?.copyWith(fontFamily: fonts.bodyFontFamily, fontWeight: fonts.bodyFontWeight),
        labelMedium: baseTheme.labelMedium?.copyWith(fontFamily: fonts.bodyFontFamily, fontWeight: fonts.bodyFontWeight),
        labelSmall: baseTheme.labelSmall?.copyWith(fontFamily: fonts.bodyFontFamily, fontWeight: fonts.bodyFontWeight),
      );
    }
  }
  ```

  **Note:** `AppSizes` is now from qtpi_ui but is re-exported via `qtpi_aliases.dart`. However, this ThemeService file is NOT importing `qtpi_aliases.dart` — it imports `package:qtpi_ui/qtpi_ui.dart' as qtpi`. `AppSizes` is not on the `qtpi` prefix. Fix by adding a bare import:
  ```dart
  import 'package:qtpi_ui/qtpi_ui.dart';
  import 'package:qtpi_ui/qtpi_ui.dart' as qtpi;
  ```
  Or import `app_sizes.dart` directly — but that file is deleted. The correct fix: `import 'package:qtpi_ui/qtpi_ui.dart';` (unaliased import for AppSizes) alongside `import 'package:qtpi_ui/qtpi_ui.dart' as qtpi;` for the prefixed ThemeService. Dart allows both.

  After this step, the `../primitives/app_sizes.dart` import should be REMOVED (the file is deleted in the next step).

- [ ] **Step 5: Delete moved primitive and structure files**

  ```bash
  rm /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter/lib/design_system/primitives/ui_scaler.dart
  rm /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter/lib/design_system/primitives/app_sizes.dart
  rm /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter/lib/design_system/primitives/app_spacings.dart
  rm /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter/lib/design_system/structures/column.dart
  rm /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter/lib/design_system/structures/row.dart
  rm /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter/lib/design_system/structures/group.dart
  ```

- [ ] **Step 6: Fix broken imports across quanitya**

  ```bash
  cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter analyze 2>&1 | grep "error\|Error" | head -40
  ```

  For every import error pointing to a deleted file, replace with `import 'package:qtpi_ui/qtpi_ui.dart';`. Also check `lib/design_system/theme/app_theme.dart` — it imports `app_sizes.dart` (now gone); fix to `package:qtpi_ui/qtpi_ui.dart`.

  **Note on quanitya's `analytics_grid.dart`**: this file in `lib/design_system/primitives/` references spacing/size tokens. Check if it imports any deleted files and fix.

- [ ] **Step 7: Run `flutter analyze` — verify zero errors**

  ```bash
  cd /Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter && flutter analyze
  ```
  Expected: zero errors.

- [ ] **Step 8: Commit quanitya migration**

  ```bash
  cd /Users/aicoder/Documents/openops/project/quanitya
  git add public/quanitya_flutter/pubspec.yaml \
          public/quanitya_flutter/pubspec.lock \
          public/quanitya_flutter/lib/design_system/
  git commit -m "feat(deps): migrate quanitya design system bones to qtpi_ui"
  ```

---

## Self-Review

**Spec coverage check:**

| Spec section | Covered by task |
|---|---|
| §3.1 Home — local git, path dep | Task 1 |
| §3.2 What moves — primitives + structures | Tasks 2, 3 |
| §3.4 typedef aliases (no rename) | Tasks 5, 6 |
| §3.5 Palette injection + override map | Task 4 |
| §3.6 Migration order (episutra first, then quanitya) | Tasks 5, 6 |
| §3.7 `flutter_color_palette` HTTPS pin | Tasks 1, 5 |
| §3.7 No injectable in qtpi_ui | Global Constraints |
| §3.8 Two-repo blast radius noted | Context sections |
| App theme stays per-app | Tasks 5, 6 (app_theme.dart untouched) |
| `context.colors` stays per-app | Tasks 5, 6 (context_extensions.dart untouched) |

**Gaps found and addressed:**
- `ThemeService` dark/light palette pair: handled via `lightPalette` + optional `darkPalette` constructor.
- quanitya's `buildAiTheme` preserved as subclass method (Task 6, Step 4).
- `DsColumn` gets `mainAxisSize` to match quanitya's existing API (Task 3).
- `DsGroup` drops `GlowTap` — uses `InkWell` as common denominator. Episutra's call sites using `EpisutraGroup` typedef get `DsGroup`, which changes the tap animation from glow-pulse to ripple. This is an acceptable trade-off for the shared package; the glow can be re-added per-app later if needed.
- Import path for quanitya pubspec path dep carefully computed (5 levels up to Documents).
