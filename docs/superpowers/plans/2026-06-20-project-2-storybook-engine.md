# Storybook Engine (Project 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an app-agnostic native-Flutter Storybook engine in `qtpi_ui` — a visual catalog where you browse every widget/token/state, edit colors live, and preview at different device sizes — hosted as standalone Flutter web apps.

**Architecture:** The engine is a library inside `qtpi_ui`, exported through a separate `package:qtpi_ui/storybook.dart` barrel so production app bundles never pull it unless they opt in. It renders a `List<Story>` against a `ThemeController` adapter that wraps the **existing** Project-1 `ThemeService` (color overrides + dark mode, already shipped) and `UiScaler`. Device-size preview comes from a new `ScreenMetrics` seam on `UiScaler` — `init(context)` keeps working unchanged; a `FixedScreenMetrics(width)` drives the stage to a simulated device width. The storybook *chrome* is built in plain Flutter (no `UiScaler`) so only the *stage* rescales, and **no app call site changes**.

**Tech Stack:** Dart/Flutter, `flutter_color_palette` (already a dep), `flutter_test`. No new runtime dependencies (the color editor is a hex field, not an external picker package).

## Global Constraints

- `qtpi_ui` runtime dependencies stay minimal: `flutter` + `flutter_color_palette` only. **Do NOT add any new package dependency.** (spec §3.7)
- `qtpi_ui` must **never import an app** (episutra/quanitya) — it is a pub-rejected cycle. (spec §4.0)
- **Zero churn to existing app call sites.** `UiScaler.instance.px(...)` and `init(BuildContext)` keep their exact current signatures and behavior. (spec §4.4.1)
- The storybook **chrome** (sidebar / tools / device frame) is built in plain Flutter and must **not** call `UiScaler`. Only the **stage** content uses it. (spec §4.2)
- "Copy palette as Dart" must emit the full `AppColorPalette(colors:{ 'k': const Color(0x________) }, name: '…')` wrapper with 8-hex-digit uppercase ARGB values — **not** a bare map. (spec §4.4)
- Fonts/sizes are **browse-only** (code + hot-reload). Colors are the only live-edited tokens. (spec §4.3)
- No mounted `/storybook` route in v1. Standalone web hosts only. (spec §4.0)
- SDK floor `>=3.0.0 <4.0.0`, `flutter >=3.0.0` (matches `pubspec.yaml`).
- Engine code lives under `lib/src/storybook/`; exported via new `lib/storybook.dart` barrel (kept OUT of `lib/qtpi_ui.dart`).
- Tests mirror `lib/src/...` under `test/...`, following the existing `test/theme/theme_service_test.dart` style (group + `flutter_test`).

---

## File Structure

**Phase A — engine foundations (pure logic, `qtpi_ui`)**
- `lib/src/primitives/screen_metrics.dart` — `ScreenMetrics` interface + `FixedScreenMetrics` / `MediaQueryScreenMetrics`.
- `lib/src/primitives/ui_scaler.dart` *(modify)* — add `initFrom(ScreenMetrics)`; `init(context)` delegates.
- `lib/src/storybook/story.dart` — `Story` model + `StoryCategory` grouping helper.
- `lib/src/storybook/device_preset.dart` — named device widths.
- `lib/src/storybook/theme_controller.dart` — `ThemeController` interface + `StorybookThemeController` adapter.
- `lib/src/storybook/palette_dart_serializer.dart` — pure "copy as Dart" function.
- `lib/src/storybook/contrast.dart` — WCAG contrast ratio + rating.

**Phase B — engine UI + `qtpi_ui` host (`qtpi_ui`)**
- `lib/src/storybook/widgets/states_grid.dart` — labeled states layout.
- `lib/src/storybook/widgets/palette_editor.dart` — per-token swatch + hex field.
- `lib/src/storybook/widgets/contrast_calculator.dart` — two token pickers + ratio badge.
- `lib/src/storybook/widgets/device_frame.dart` — fixed-width stage frame + UiScaler re-init.
- `lib/src/storybook/storybook_app.dart` — 3-pane scaffold (sidebar / stage / tools).
- `lib/src/storybook/stories/qtpi_stories.dart` — qtpi_ui's own story set (tokens + structures).
- `lib/storybook.dart` — public barrel for the engine.
- `example/lib/main.dart` — qtpi_ui standalone web host.
- `example/pubspec.yaml` — example app manifest (path dep on qtpi_ui).

**Phase C — episutra host (`episutra` repo — separate build cycle, see note)**
- `episutra_flutter/lib/design_system/storybook/episutra_stories.dart`
- `episutra_flutter/lib/storybook_main.dart`

> **Scope note:** Phase C lands in a different repo and depends on Phases A–B being published. It can be split into its own plan if preferred; it is included here because the agreed scope is "Engine + qtpi_ui + episutra." quanitya's story set is explicitly deferred (spec §5).

---

## Task 1: `ScreenMetrics` seam on `UiScaler`

**Files:**
- Create: `lib/src/primitives/screen_metrics.dart`
- Modify: `lib/src/primitives/ui_scaler.dart`
- Test: `test/primitives/screen_metrics_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `abstract interface class ScreenMetrics { double get width; }`; `class FixedScreenMetrics implements ScreenMetrics`; `class MediaQueryScreenMetrics implements ScreenMetrics`; `UiScaler.instance.initFrom(ScreenMetrics)`. Existing `UiScaler.init(BuildContext)` and `px`/`sp`/`scaleFactor` unchanged.

- [ ] **Step 1: Write the failing test**

```dart
// test/primitives/screen_metrics_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';

void main() {
  group('UiScaler.initFrom', () {
    test('FixedScreenMetrics at baseline width yields scaleFactor 1.0', () {
      UiScaler.instance.initFrom(const FixedScreenMetrics(393.0));
      expect(UiScaler.instance.scaleFactor, 1.0);
    });

    test('wider width scales up, clamped to 1.15', () {
      UiScaler.instance.initFrom(const FixedScreenMetrics(820.0)); // iPad
      expect(UiScaler.instance.scaleFactor, 1.15);
    });

    test('narrower width scales down, clamped to 0.85', () {
      UiScaler.instance.initFrom(const FixedScreenMetrics(200.0));
      expect(UiScaler.instance.scaleFactor, 0.85);
    });

    test('px multiplies by the simulated factor', () {
      UiScaler.instance.initFrom(const FixedScreenMetrics(393.0));
      expect(UiScaler.instance.px(10.0), 10.0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/primitives/screen_metrics_test.dart`
Expected: FAIL — `FixedScreenMetrics` / `initFrom` not defined.

- [ ] **Step 3: Create the `ScreenMetrics` seam**

```dart
// lib/src/primitives/screen_metrics.dart
import 'package:flutter/material.dart';

/// Source of the screen width that [UiScaler] derives its factor from.
/// Lets the Storybook drive a simulated device width without touching
/// any production call site.
abstract interface class ScreenMetrics {
  double get width;
}

/// Production source — reads the live window via MediaQuery.
class MediaQueryScreenMetrics implements ScreenMetrics {
  const MediaQueryScreenMetrics(this.context);
  final BuildContext context;
  @override
  double get width => MediaQuery.of(context).size.width;
}

/// Storybook source — a fixed simulated device width (e.g. iPad @ 820).
class FixedScreenMetrics implements ScreenMetrics {
  const FixedScreenMetrics(this.width);
  @override
  final double width;
}
```

- [ ] **Step 4: Route `UiScaler` through the seam**

Modify `lib/src/primitives/ui_scaler.dart`. Add the import at the top:

```dart
import 'screen_metrics.dart';
```

Replace the existing `init` method (lines 19-30) with:

```dart
  /// Initialize the scaler. Call from MaterialApp.builder.
  void init(BuildContext context) => initFrom(MediaQueryScreenMetrics(context));

  /// Initialize from any [ScreenMetrics] source. Production uses
  /// [MediaQueryScreenMetrics]; the Storybook uses [FixedScreenMetrics].
  void initFrom(ScreenMetrics metrics) {
    _screenWidth = metrics.width;

    // Clamp to prevent extreme scaling on very small/large devices
    const double minScale = 0.85;
    const double maxScale = 1.15;

    final rawFactor = _screenWidth / _baseWidth;
    _scaleFactor = rawFactor.clamp(minScale, maxScale);
    _initialized = true;
  }
```

- [ ] **Step 5: Export the new file**

Add to `lib/qtpi_ui.dart` after the `ui_scaler.dart` export (line 4):

```dart
export 'src/primitives/screen_metrics.dart';
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/primitives/screen_metrics_test.dart test/primitives/ui_scaler_test.dart`
Expected: PASS (new file green; existing `ui_scaler_test.dart` still green — `init(context)` behavior is unchanged).

- [ ] **Step 7: Commit**

```bash
git add lib/src/primitives/screen_metrics.dart lib/src/primitives/ui_scaler.dart lib/qtpi_ui.dart test/primitives/screen_metrics_test.dart
git commit -m "feat(storybook): add ScreenMetrics seam to UiScaler for device-size preview"
```

---

## Task 2: `Story` model + category grouping

**Files:**
- Create: `lib/src/storybook/story.dart`
- Test: `test/storybook/story_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `class Story { final String category; final String name; final WidgetBuilder builder; }`; `List<StoryCategory> groupStories(List<Story>)` returning `class StoryCategory { final String name; final List<Story> stories; }` in first-seen order.

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/story_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  Story story(String cat, String name) =>
      Story(category: cat, name: name, builder: (_) => const SizedBox());

  group('groupStories', () {
    test('groups by category preserving first-seen order', () {
      final grouped = groupStories([
        story('Tokens', 'Colors'),
        story('Structures', 'DsRow'),
        story('Tokens', 'Spacing'),
      ]);
      expect(grouped.map((g) => g.name).toList(), ['Tokens', 'Structures']);
      expect(grouped.first.stories.map((s) => s.name).toList(),
          ['Colors', 'Spacing']);
    });

    test('empty input yields empty list', () {
      expect(groupStories(const []), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/story_test.dart`
Expected: FAIL — `package:qtpi_ui/storybook.dart` / `Story` not found.

- [ ] **Step 3: Write the model**

```dart
// lib/src/storybook/story.dart
import 'package:flutter/widgets.dart';

/// A single catalog entry: how to build one widget/token demo.
class Story {
  const Story({
    required this.category,
    required this.name,
    required this.builder,
  });

  final String category;
  final String name;
  final WidgetBuilder builder;
}

/// A category with its stories, in first-seen order.
class StoryCategory {
  StoryCategory(this.name) : stories = [];
  final String name;
  final List<Story> stories;
}

/// Groups stories by [Story.category], preserving first-seen order of both
/// categories and stories.
List<StoryCategory> groupStories(List<Story> stories) {
  final byName = <String, StoryCategory>{};
  final order = <StoryCategory>[];
  for (final s in stories) {
    final cat = byName.putIfAbsent(s.category, () {
      final c = StoryCategory(s.category);
      order.add(c);
      return c;
    });
    cat.stories.add(s);
  }
  return order;
}
```

- [ ] **Step 4: Create the storybook barrel and run the test**

```dart
// lib/storybook.dart
library qtpi_ui.storybook;

export 'src/storybook/story.dart';
```

Run: `flutter test test/storybook/story_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/storybook/story.dart lib/storybook.dart test/storybook/story_test.dart
git commit -m "feat(storybook): add Story model and category grouping"
```

---

## Task 3: Device presets

**Files:**
- Create: `lib/src/storybook/device_preset.dart`
- Modify: `lib/storybook.dart`
- Test: `test/storybook/device_preset_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `class DevicePreset { final String name; final double width; }`; `DevicePreset.defaults` (`List<DevicePreset>`); constants `iphoneSE`, `iphone16`, `proMax`, `ipad`, `desktop`.

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/device_preset_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  group('DevicePreset', () {
    test('iphone16 is the 393dp baseline', () {
      expect(DevicePreset.iphone16.width, 393.0);
    });

    test('defaults run phone -> desktop in ascending width', () {
      final widths = DevicePreset.defaults.map((d) => d.width).toList();
      expect(widths, [375.0, 393.0, 430.0, 820.0, 1200.0]);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/device_preset_test.dart`
Expected: FAIL — `DevicePreset` not found.

- [ ] **Step 3: Write the presets**

```dart
// lib/src/storybook/device_preset.dart
/// A named simulated device width for the Storybook stage.
class DevicePreset {
  const DevicePreset(this.name, this.width);
  final String name;
  final double width;

  static const iphoneSE = DevicePreset('iPhone SE', 375.0);
  static const iphone16 = DevicePreset('iPhone 16', 393.0);
  static const proMax = DevicePreset('iPhone Pro Max', 430.0);
  static const ipad = DevicePreset('iPad', 820.0);
  static const desktop = DevicePreset('Desktop', 1200.0);

  static const List<DevicePreset> defaults = [
    iphoneSE,
    iphone16,
    proMax,
    ipad,
    desktop,
  ];
}
```

- [ ] **Step 4: Export and run the test**

Add to `lib/storybook.dart`:

```dart
export 'src/storybook/device_preset.dart';
```

Run: `flutter test test/storybook/device_preset_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/storybook/device_preset.dart lib/storybook.dart test/storybook/device_preset_test.dart
git commit -m "feat(storybook): add device-size presets"
```

---

## Task 4: `ThemeController` adapter

**Files:**
- Create: `lib/src/storybook/theme_controller.dart`
- Modify: `lib/storybook.dart`
- Test: `test/storybook/theme_controller_test.dart`

**Interfaces:**
- Consumes: `ThemeService` (from `qtpi_ui.dart`), `DevicePreset` (Task 3).
- Produces: `abstract interface class ThemeController`; `class StorybookThemeController extends ChangeNotifier implements ThemeController` with `Map<String,Color> get tokens`, `setToken(String,Color)`, `reset()`, `bool isDark` get/set, `DevicePreset? devicePreset` get/set, `String paletteName`. The controller stores `devicePreset` and notifies; it does **not** mutate `UiScaler` (that happens in the `DeviceFrame` widget, Task 9, which has a `BuildContext`).

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/theme_controller_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';

ThemeService _svc() => ThemeService(
      lightPalette: AppColorPalette(
        colors: {'color1': const Color(0xFF0B152C)},
        name: 'Test',
      ),
    );

void main() {
  group('StorybookThemeController', () {
    test('tokens reflect the service palette', () {
      final c = StorybookThemeController(_svc());
      expect(c.tokens['color1'], const Color(0xFF0B152C));
    });

    test('setToken overrides a color and notifies', () {
      final c = StorybookThemeController(_svc());
      var notified = false;
      c.addListener(() => notified = true);
      c.setToken('color1', const Color(0xFFABCDEF));
      expect(c.tokens['color1'], const Color(0xFFABCDEF));
      expect(notified, isTrue);
    });

    test('reset clears overrides', () {
      final c = StorybookThemeController(_svc());
      c.setToken('color1', const Color(0xFFABCDEF));
      c.reset();
      expect(c.tokens['color1'], const Color(0xFF0B152C));
    });

    test('isDark setter drives the service', () {
      final c = StorybookThemeController(_svc());
      c.isDark = true;
      expect(c.isDark, isTrue);
    });

    test('devicePreset stores and notifies', () {
      final c = StorybookThemeController(_svc());
      var notified = false;
      c.addListener(() => notified = true);
      c.devicePreset = DevicePreset.ipad;
      expect(c.devicePreset, DevicePreset.ipad);
      expect(notified, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/theme_controller_test.dart`
Expected: FAIL — `StorybookThemeController` not found.

- [ ] **Step 3: Write the controller**

```dart
// lib/src/storybook/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'device_preset.dart';

/// What the engine needs from a theme, with nothing app-specific. Backed by the
/// Project-1 [ThemeService] (color overrides + dark mode are already built).
abstract interface class ThemeController implements Listenable {
  Map<String, Color> get tokens;
  String get paletteName;
  void setToken(String key, Color value);
  void reset();
  bool get isDark;
  set isDark(bool value);
  DevicePreset? get devicePreset;
  set devicePreset(DevicePreset? value);
}

/// Adapter composing the real [ThemeService] (color + dark) with a selected
/// [DevicePreset]. The preset is applied to [UiScaler] by the DeviceFrame
/// widget (which owns a BuildContext); this controller only holds state.
class StorybookThemeController extends ChangeNotifier
    implements ThemeController {
  StorybookThemeController(this._theme) {
    _theme.addListener(notifyListeners);
  }

  final ThemeService _theme;
  DevicePreset? _preset;

  @override
  Map<String, Color> get tokens => _theme.currentPalette.colors;

  @override
  String get paletteName => _theme.currentPalette.name;

  @override
  void setToken(String key, Color value) => _theme.setOverride(key, value);

  @override
  void reset() => _theme.clearOverrides();

  @override
  bool get isDark => _theme.isDarkMode;

  @override
  set isDark(bool value) => _theme.setDarkMode(value);

  @override
  DevicePreset? get devicePreset => _preset;

  @override
  set devicePreset(DevicePreset? value) {
    _preset = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _theme.removeListener(notifyListeners);
    super.dispose();
  }
}
```

- [ ] **Step 4: Export and run the test**

Add to `lib/storybook.dart`:

```dart
export 'src/storybook/theme_controller.dart';
```

Run: `flutter test test/storybook/theme_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/storybook/theme_controller.dart lib/storybook.dart test/storybook/theme_controller_test.dart
git commit -m "feat(storybook): add ThemeController adapter over ThemeService"
```

---

## Task 5: "Copy palette as Dart" serializer

**Files:**
- Create: `lib/src/storybook/palette_dart_serializer.dart`
- Modify: `lib/storybook.dart`
- Test: `test/storybook/palette_dart_serializer_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `String paletteToDart(Map<String, Color> colors, {required String name})` returning the exact `AppColorPalette(colors:{…}, name:'…')` source literal.

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/palette_dart_serializer_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  group('paletteToDart', () {
    test('emits the AppColorPalette wrapper with 8-hex uppercase colors', () {
      final out = paletteToDart(
        {
          'color1': const Color(0xFF0B152C),
          'accent': const Color(0xFF00C3FF),
        },
        name: 'Episutra Bioluminescent',
      );
      expect(out, '''
AppColorPalette(
  colors: {
    'color1': const Color(0xFF0B152C),
    'accent': const Color(0xFF00C3FF),
  },
  name: 'Episutra Bioluminescent',
)''');
    });

    test('preserves non-FF alpha', () {
      final out = paletteToDart(
        {'ghost': const Color(0x0B00C3FF)},
        name: 'P',
      );
      expect(out.contains("'ghost': const Color(0x0B00C3FF),"), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/palette_dart_serializer_test.dart`
Expected: FAIL — `paletteToDart` not found.

- [ ] **Step 3: Write the serializer**

```dart
// lib/src/storybook/palette_dart_serializer.dart
import 'package:flutter/material.dart';

/// Serializes a live palette back into the exact Dart source both apps use:
///
/// ```dart
/// AppColorPalette(
///   colors: {
///     'color1': const Color(0xFF0B152C),
///   },
///   name: 'Episutra Bioluminescent',
/// )
/// ```
///
/// Note: hand-written `// comments` in the source palette files cannot be
/// reproduced — round-trip output is comment-less (spec §4.4).
String paletteToDart(Map<String, Color> colors, {required String name}) {
  final buf = StringBuffer()
    ..writeln('AppColorPalette(')
    ..writeln('  colors: {');
  colors.forEach((key, color) {
    // ignore: deprecated_member_use — .value is the stable ARGB int on the SDK floor
    final hex = color.value.toRadixString(16).toUpperCase().padLeft(8, '0');
    buf.writeln("    '$key': const Color(0x$hex),");
  });
  buf
    ..writeln('  },')
    ..writeln("  name: '$name',")
    ..write(')');
  return buf.toString();
}
```

- [ ] **Step 4: Export and run the test**

Add to `lib/storybook.dart`:

```dart
export 'src/storybook/palette_dart_serializer.dart';
```

Run: `flutter test test/storybook/palette_dart_serializer_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/storybook/palette_dart_serializer.dart lib/storybook.dart test/storybook/palette_dart_serializer_test.dart
git commit -m "feat(storybook): add copy-palette-as-Dart serializer"
```

---

## Task 6: WCAG contrast calculator

**Files:**
- Create: `lib/src/storybook/contrast.dart`
- Modify: `lib/storybook.dart`
- Test: `test/storybook/contrast_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `double contrastRatio(Color a, Color b)`; `String contrastRating(double ratio)` returning one of `'AAA'`, `'AA'`, `'AA Large'`, `'Fail'`.

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/contrast_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  group('contrast', () {
    test('black on white is 21:1', () {
      final r = contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF));
      expect(r, closeTo(21.0, 0.01));
    });

    test('identical colors are 1:1', () {
      final r = contrastRatio(const Color(0xFF123456), const Color(0xFF123456));
      expect(r, closeTo(1.0, 0.001));
    });

    test('rating thresholds', () {
      expect(contrastRating(21.0), 'AAA');     // >= 7
      expect(contrastRating(5.0), 'AA');       // >= 4.5
      expect(contrastRating(3.5), 'AA Large'); // >= 3
      expect(contrastRating(2.0), 'Fail');     // < 3
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/contrast_test.dart`
Expected: FAIL — `contrastRatio` not found.

- [ ] **Step 3: Write the calculator**

```dart
// lib/src/storybook/contrast.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

double _linearize(int channel) {
  final c = channel / 255.0;
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color c) {
  // ignore: deprecated_member_use — .red/.green/.blue are stable on the SDK floor
  return 0.2126 * _linearize(c.red) +
      0.7152 * _linearize(c.green) +
      0.0722 * _linearize(c.blue);
}

/// WCAG 2.x contrast ratio between two colors (1.0 .. 21.0).
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// WCAG pass level for normal/large body text.
String contrastRating(double ratio) {
  if (ratio >= 7.0) return 'AAA';
  if (ratio >= 4.5) return 'AA';
  if (ratio >= 3.0) return 'AA Large';
  return 'Fail';
}
```

- [ ] **Step 4: Export and run the test**

Add to `lib/storybook.dart`:

```dart
export 'src/storybook/contrast.dart';
```

Run: `flutter test test/storybook/contrast_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/storybook/contrast.dart lib/storybook.dart test/storybook/contrast_test.dart
git commit -m "feat(storybook): add WCAG contrast ratio + rating"
```

---

## Task 7: States grid widget

**Files:**
- Create: `lib/src/storybook/widgets/states_grid.dart`
- Modify: `lib/storybook.dart`
- Test: `test/storybook/states_grid_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `class StatesGrid extends StatelessWidget` with `const StatesGrid({required Map<String, WidgetBuilder> states})`; renders each entry as a labeled cell.

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/states_grid_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  testWidgets('renders a labeled cell per state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatesGrid(states: {
          'default': (_) => const Text('A'),
          'disabled': (_) => const Text('B'),
        }),
      ),
    ));
    expect(find.text('default'), findsOneWidget);
    expect(find.text('disabled'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/states_grid_test.dart`
Expected: FAIL — `StatesGrid` not found.

- [ ] **Step 3: Write the widget**

```dart
// lib/src/storybook/widgets/states_grid.dart
import 'package:flutter/material.dart';

/// Renders one widget per named state in a wrapping row of labeled cells.
/// Plain Flutter — does NOT use UiScaler (it is chrome, not stage content).
class StatesGrid extends StatelessWidget {
  const StatesGrid({super.key, required this.states});

  final Map<String, WidgetBuilder> states;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        for (final entry in states.entries)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              Builder(builder: entry.value),
            ],
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Export and run the test**

Add to `lib/storybook.dart`:

```dart
export 'src/storybook/widgets/states_grid.dart';
```

Run: `flutter test test/storybook/states_grid_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/storybook/widgets/states_grid.dart lib/storybook.dart test/storybook/states_grid_test.dart
git commit -m "feat(storybook): add StatesGrid widget"
```

---

## Task 8: Palette editor widget (live color tweaking)

**Files:**
- Create: `lib/src/storybook/widgets/palette_editor.dart`
- Modify: `lib/storybook.dart`
- Test: `test/storybook/palette_editor_test.dart`

**Interfaces:**
- Consumes: `ThemeController` (Task 4).
- Produces: `class PaletteEditor extends StatelessWidget` with `const PaletteEditor({required ThemeController controller})`; one row per token = swatch + hex `TextField`. Typing a valid 6/8-digit hex calls `controller.setToken`.

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/palette_editor_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  testWidgets('typing a hex updates the controller token', (tester) async {
    final controller = StorybookThemeController(ThemeService(
      lightPalette: AppColorPalette(
        colors: {'color1': const Color(0xFF0B152C)},
        name: 'T',
      ),
    ));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PaletteEditor(controller: controller)),
    ));

    expect(find.text('color1'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'FF00C3FF');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.tokens['color1'], const Color(0xFF00C3FF));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/palette_editor_test.dart`
Expected: FAIL — `PaletteEditor` not found.

- [ ] **Step 3: Write the widget**

```dart
// lib/src/storybook/widgets/palette_editor.dart
import 'package:flutter/material.dart';
import 'theme_controller_import.dart';

/// One editable row per palette token: a swatch + a hex field. Plain Flutter.
/// Entering a valid 6- (RRGGBB) or 8-digit (AARRGGBB) hex applies a live
/// override via [ThemeController.setToken].
class PaletteEditor extends StatelessWidget {
  const PaletteEditor({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final tokens = controller.tokens;
        return ListView(
          shrinkWrap: true,
          children: [
            for (final entry in tokens.entries)
              _TokenRow(
                name: entry.key,
                color: entry.value,
                onHex: (color) => controller.setToken(entry.key, color),
              ),
          ],
        );
      },
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.name, required this.color, required this.onHex});

  final String name;
  final Color color;
  final ValueChanged<Color> onHex;

  static Color? _parseHex(String raw) {
    var hex = raw.trim().replaceAll('#', '').toUpperCase();
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final initial = color.value.toRadixString(16).toUpperCase().padLeft(8, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          SizedBox(
            width: 110,
            child: TextField(
              key: ValueKey('hex_$name'),
              controller: TextEditingController(text: initial),
              decoration: const InputDecoration(prefixText: '0x', isDense: true),
              onSubmitted: (raw) {
                final parsed = _parseHex(raw);
                if (parsed != null) onHex(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Add the local re-export shim and export the widget**

Create `lib/src/storybook/widgets/theme_controller_import.dart`:

```dart
// Local re-export so widget files import ThemeController by relative path.
export '../theme_controller.dart';
```

Add to `lib/storybook.dart`:

```dart
export 'src/storybook/widgets/palette_editor.dart';
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/storybook/palette_editor_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/src/storybook/widgets/palette_editor.dart lib/src/storybook/widgets/theme_controller_import.dart lib/storybook.dart test/storybook/palette_editor_test.dart
git commit -m "feat(storybook): add live PaletteEditor (hex field per token)"
```

---

## Task 9: Device frame widget (stage scaling)

**Files:**
- Create: `lib/src/storybook/widgets/device_frame.dart`
- Modify: `lib/storybook.dart`
- Test: `test/storybook/device_frame_test.dart`

**Interfaces:**
- Consumes: `DevicePreset` (Task 3), `FixedScreenMetrics` / `MediaQueryScreenMetrics` + `UiScaler` (Task 1).
- Produces: `class DeviceFrame extends StatelessWidget` with `const DeviceFrame({DevicePreset? preset, required Widget child})`. When `preset != null`, re-inits `UiScaler` to `FixedScreenMetrics(preset.width)` and constrains the child to that width inside a `MediaQuery` override; when null, re-inits from context.

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/device_frame_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  testWidgets('preset drives UiScaler to the device width factor',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeviceFrame(
          preset: DevicePreset.ipad, // 820 -> clamps to 1.15
          child: const SizedBox(),
        ),
      ),
    ));
    expect(UiScaler.instance.scaleFactor, 1.15);
  });

  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeviceFrame(
          preset: DevicePreset.iphone16,
          child: const Text('stage'),
        ),
      ),
    ));
    expect(find.text('stage'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/device_frame_test.dart`
Expected: FAIL — `DeviceFrame` not found.

- [ ] **Step 3: Write the widget**

```dart
// lib/src/storybook/widgets/device_frame.dart
import 'package:flutter/material.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import '../device_preset.dart';

/// Frames the stage at a simulated device width and points [UiScaler] at that
/// same width, so token-sized widgets follow the preview. When [preset] is
/// null, falls back to the real window. Re-init happens here (not in the
/// controller) because this widget owns a BuildContext.
class DeviceFrame extends StatelessWidget {
  const DeviceFrame({super.key, this.preset, required this.child});

  final DevicePreset? preset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = preset;
    if (p == null) {
      UiScaler.instance.init(context);
      return child;
    }
    UiScaler.instance.initFrom(FixedScreenMetrics(p.width));
    final media = MediaQuery.of(context);
    return Center(
      child: Container(
        width: p.width,
        decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
        child: MediaQuery(
          data: media.copyWith(size: Size(p.width, media.size.height)),
          child: child,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Export and run the test**

Add to `lib/storybook.dart`:

```dart
export 'src/storybook/widgets/device_frame.dart';
```

Run: `flutter test test/storybook/device_frame_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/storybook/widgets/device_frame.dart lib/storybook.dart test/storybook/device_frame_test.dart
git commit -m "feat(storybook): add DeviceFrame stage scaling"
```

---

## Task 10: Contrast calculator widget

**Files:**
- Create: `lib/src/storybook/widgets/contrast_calculator.dart`
- Modify: `lib/storybook.dart`
- Test: `test/storybook/contrast_calculator_test.dart`

**Interfaces:**
- Consumes: `contrastRatio` / `contrastRating` (Task 6).
- Produces: `class ContrastCalculator extends StatefulWidget` with `const ContrastCalculator({required Map<String, Color> tokens})`; two token dropdowns + a ratio + rating badge.

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/contrast_calculator_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  testWidgets('shows 21.00 and AAA for black vs white default selection',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContrastCalculator(tokens: {
          'black': const Color(0xFF000000),
          'white': const Color(0xFFFFFFFF),
        }),
      ),
    ));
    expect(find.textContaining('21.00'), findsOneWidget);
    expect(find.text('AAA'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/contrast_calculator_test.dart`
Expected: FAIL — `ContrastCalculator` not found.

- [ ] **Step 3: Write the widget**

```dart
// lib/src/storybook/widgets/contrast_calculator.dart
import 'package:flutter/material.dart';
import '../contrast.dart';

/// Pick two tokens -> WCAG ratio + AA/AAA badge. Plain Flutter chrome.
class ContrastCalculator extends StatefulWidget {
  const ContrastCalculator({super.key, required this.tokens});

  final Map<String, Color> tokens;

  @override
  State<ContrastCalculator> createState() => _ContrastCalculatorState();
}

class _ContrastCalculatorState extends State<ContrastCalculator> {
  late String _a = widget.tokens.keys.first;
  late String _b = widget.tokens.keys.length > 1
      ? widget.tokens.keys.elementAt(1)
      : widget.tokens.keys.first;

  @override
  Widget build(BuildContext context) {
    final ratio = contrastRatio(widget.tokens[_a]!, widget.tokens[_b]!);
    final rating = contrastRating(ratio);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dropdown(_a, (v) => setState(() => _a = v!)),
        _dropdown(_b, (v) => setState(() => _b = v!)),
        const SizedBox(height: 8),
        Text('${ratio.toStringAsFixed(2)} : 1'),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          color: rating == 'Fail' ? Colors.red.shade100 : Colors.green.shade100,
          child: Text(rating),
        ),
      ],
    );
  }

  Widget _dropdown(String value, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: value,
      onChanged: onChanged,
      items: [
        for (final key in widget.tokens.keys)
          DropdownMenuItem(value: key, child: Text(key)),
      ],
    );
  }
}
```

- [ ] **Step 4: Export and run the test**

Add to `lib/storybook.dart`:

```dart
export 'src/storybook/widgets/contrast_calculator.dart';
```

Run: `flutter test test/storybook/contrast_calculator_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/storybook/widgets/contrast_calculator.dart lib/storybook.dart test/storybook/contrast_calculator_test.dart
git commit -m "feat(storybook): add ContrastCalculator widget"
```

---

## Task 11: Storybook app scaffold (3-pane)

**Files:**
- Create: `lib/src/storybook/storybook_app.dart`
- Modify: `lib/storybook.dart`
- Test: `test/storybook/storybook_app_test.dart`

**Interfaces:**
- Consumes: `Story`/`groupStories` (Task 2), `ThemeController` (Task 4), `StatesGrid` (Task 7), `PaletteEditor` (Task 8), `DeviceFrame` (Task 9), `ContrastCalculator` (Task 10), `DevicePreset` (Task 3), `paletteToDart` (Task 5).
- Produces: `class StorybookApp extends StatefulWidget` with `const StorybookApp({required List<Story> stories, required ThemeController controller, required ThemeData Function(ThemeController) themeBuilder})`. Left sidebar selects a story; center renders it in a `DeviceFrame`; right panel shows preset selector + dark toggle + palette editor + contrast + "copy as Dart".

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/storybook_app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  testWidgets('renders sidebar entries and the selected story', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    final controller = StorybookThemeController(ThemeService(
      lightPalette: AppColorPalette(
        colors: {'color1': const Color(0xFF0B152C)},
        name: 'T',
      ),
    ));

    await tester.pumpWidget(StorybookApp(
      controller: controller,
      themeBuilder: (_) => ThemeData.dark(),
      stories: [
        Story(
          category: 'Tokens',
          name: 'Colors',
          builder: (_) => const Text('color-gallery'),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tokens'), findsOneWidget);
    expect(find.text('Colors'), findsWidgets);
    expect(find.text('color-gallery'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/storybook_app_test.dart`
Expected: FAIL — `StorybookApp` not found.

- [ ] **Step 3: Write the scaffold**

```dart
// lib/src/storybook/storybook_app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'device_preset.dart';
import 'palette_dart_serializer.dart';
import 'story.dart';
import 'theme_controller.dart';
import 'widgets/contrast_calculator.dart';
import 'widgets/device_frame.dart';
import 'widgets/palette_editor.dart';

/// The app-agnostic Storybook shell. Chrome is plain Flutter; only the stage
/// (inside [DeviceFrame]) uses UiScaler.
class StorybookApp extends StatefulWidget {
  const StorybookApp({
    super.key,
    required this.stories,
    required this.controller,
    required this.themeBuilder,
  });

  final List<Story> stories;
  final ThemeController controller;
  final ThemeData Function(ThemeController) themeBuilder;

  @override
  State<StorybookApp> createState() => _StorybookAppState();
}

class _StorybookAppState extends State<StorybookApp> {
  late Story _selected = widget.stories.first;

  @override
  Widget build(BuildContext context) {
    final categories = groupStories(widget.stories);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: widget.themeBuilder(widget.controller),
          home: Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  categories: categories,
                  selected: _selected,
                  onSelect: (s) => setState(() => _selected = s),
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: DeviceFrame(
                      preset: widget.controller.devicePreset,
                      child: Builder(builder: _selected.builder),
                    ),
                  ),
                ),
                _ToolsPanel(controller: widget.controller),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<StoryCategory> categories;
  final Story selected;
  final ValueChanged<Story> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Material(
        color: Colors.black12,
        child: ListView(
          children: [
            for (final cat in categories) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(cat.name,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              for (final story in cat.stories)
                ListTile(
                  dense: true,
                  selected: identical(story, selected),
                  title: Text(story.name),
                  onTap: () => onSelect(story),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolsPanel extends StatelessWidget {
  const _ToolsPanel({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Material(
        color: Colors.black12,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text('Device'),
            DropdownButton<DevicePreset?>(
              value: controller.devicePreset,
              hint: const Text('Fit window'),
              isExpanded: true,
              onChanged: (v) => controller.devicePreset = v,
              items: [
                const DropdownMenuItem(value: null, child: Text('Fit window')),
                for (final p in DevicePreset.defaults)
                  DropdownMenuItem(
                      value: p, child: Text('${p.name} (${p.width.toInt()})')),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark mode'),
              value: controller.isDark,
              onChanged: (v) => controller.isDark = v,
            ),
            const Divider(),
            const Text('Palette'),
            SizedBox(height: 300, child: PaletteEditor(controller: controller)),
            TextButton(
              onPressed: () {
                final dart = paletteToDart(controller.tokens,
                    name: controller.paletteName);
                Clipboard.setData(ClipboardData(text: dart));
              },
              child: const Text('Copy palette as Dart'),
            ),
            TextButton(
              onPressed: controller.reset,
              child: const Text('Reset overrides'),
            ),
            const Divider(),
            const Text('Contrast'),
            ContrastCalculator(tokens: controller.tokens),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Export and run the test**

Add to `lib/storybook.dart`:

```dart
export 'src/storybook/storybook_app.dart';
```

Run: `flutter test test/storybook/storybook_app_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/storybook/storybook_app.dart lib/storybook.dart test/storybook/storybook_app_test.dart
git commit -m "feat(storybook): add 3-pane StorybookApp scaffold"
```

---

## Task 12: qtpi_ui story set (tokens + structures)

**Files:**
- Create: `lib/src/storybook/stories/qtpi_stories.dart`
- Modify: `lib/storybook.dart`
- Test: `test/storybook/qtpi_stories_test.dart`

**Interfaces:**
- Consumes: `Story` (Task 2), `AppSizes`/`DsColumn`/`DsRow`/`DsGroup` (from `qtpi_ui.dart`).
- Produces: `List<Story> qtpiStories(Map<String, Color> tokens)` — Tokens (Colors swatches, Spacing rulers) + Structures (DsColumn/DsRow/DsGroup) stories.

- [ ] **Step 1: Write the failing test**

```dart
// test/storybook/qtpi_stories_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  group('qtpiStories', () {
    test('includes Tokens and Structures categories', () {
      final stories = qtpiStories({'color1': const Color(0xFF0B152C)});
      final cats = stories.map((s) => s.category).toSet();
      expect(cats, containsAll(['Tokens', 'Structures']));
    });

    test('a colors story builds without throwing', () {
      final stories = qtpiStories({'color1': const Color(0xFF0B152C)});
      final colors = stories.firstWhere((s) => s.name == 'Colors');
      expect(colors.builder, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/storybook/qtpi_stories_test.dart`
Expected: FAIL — `qtpiStories` not found.

- [ ] **Step 3: Write the story set**

```dart
// lib/src/storybook/stories/qtpi_stories.dart
import 'package:flutter/material.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import '../story.dart';

/// qtpi_ui's own catalog: tokens + the Ds* structure primitives. App-agnostic;
/// [tokens] is the live palette map so the colors gallery re-renders on edits.
List<Story> qtpiStories(Map<String, Color> tokens) => [
      Story(
        category: 'Tokens',
        name: 'Colors',
        builder: (context) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in tokens.entries)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: entry.value,
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.key, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
          ],
        ),
      ),
      Story(
        category: 'Tokens',
        name: 'Spacing',
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final spec in [
              ('spaceHalf', AppSizes.spaceHalf),
              ('space', AppSizes.space),
              ('radiusMedium', AppSizes.radiusMedium),
              ('buttonHeight', AppSizes.buttonHeight),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(spec.$1)),
                    Container(
                        width: spec.$2,
                        height: 16,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(spec.$2.toStringAsFixed(1)),
                  ],
                ),
              ),
          ],
        ),
      ),
      Story(
        category: 'Structures',
        name: 'DsColumn',
        builder: (_) => const DsColumn(
          children: [Text('one'), Text('two'), Text('three')],
        ),
      ),
      Story(
        category: 'Structures',
        name: 'DsRow',
        builder: (_) => const DsRow(
          children: [Text('left'), Text('mid'), Text('right')],
        ),
      ),
      Story(
        category: 'Structures',
        name: 'DsGroup',
        builder: (_) => DsGroup(
          showChevron: true,
          onTap: () {},
          child: const Text('Tappable group row'),
        ),
      ),
    ];
```

> **Note for implementer:** confirm the `DsColumn`/`DsRow` constructor param is `children:` by checking `lib/src/structures/ds_column.dart`. If the constructor differs, match it — do not invent a signature.

- [ ] **Step 4: Export and run the test**

Add to `lib/storybook.dart`:

```dart
export 'src/storybook/stories/qtpi_stories.dart';
```

Run: `flutter test test/storybook/qtpi_stories_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/storybook/stories/qtpi_stories.dart lib/storybook.dart test/storybook/qtpi_stories_test.dart
git commit -m "feat(storybook): add qtpi_ui story set (tokens + structures)"
```

---

## Task 13: Standalone `example/` web host

**Files:**
- Create: `example/pubspec.yaml`
- Create: `example/lib/main.dart`
- (Generated by `flutter create`: `example/web/`, `example/.metadata`, etc.)

**Interfaces:**
- Consumes: `StorybookApp`, `StorybookThemeController`, `qtpiStories` (Tasks 11–12), `ThemeService` (qtpi_ui).
- Produces: a runnable web app. No automated test — manual verification step.

- [ ] **Step 1: Scaffold the example app**

Run:
```bash
flutter create --template=app --platforms=web,macos example
```
Expected: creates `example/` with web + macOS runners.

- [ ] **Step 2: Point the example at the local package**

Replace `example/pubspec.yaml` dependencies block so it path-depends on the parent package:

```yaml
name: qtpi_ui_storybook
description: Standalone Storybook host for qtpi_ui.
publish_to: 'none'
version: 0.1.0

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.0.0'

dependencies:
  flutter:
    sdk: flutter
  qtpi_ui:
    path: ../
  flutter_color_palette:
    git:
      url: https://github.com/qtpi-bonding-org/flutter_color_palette.git
      ref: e8755f5993cb66c6dfd4696df87bf6ef64229756

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Write the host entrypoint**

```dart
// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';

// A demo palette so the engine has tokens to show. Apps supply their own.
final _demoPalette = AppColorPalette(
  colors: {
    'color1': const Color(0xFF0B152C),
    'color2': const Color(0xFFE8EFFF),
    'color3': const Color(0xFF00C3FF),
    'interactable': const Color(0xFF00C3FF),
    'error': const Color(0xFF3D1616),
  },
  name: 'qtpi_ui Demo',
);

void main() {
  final theme = ThemeService(lightPalette: _demoPalette);
  final controller = StorybookThemeController(theme);
  runApp(StorybookApp(
    controller: controller,
    themeBuilder: (c) => ThemeData(
      brightness: c.isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.tokens['color3'] ?? const Color(0xFF00C3FF),
        brightness: c.isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: c.tokens['color1'],
    ),
    stories: qtpiStories(controller.tokens),
  ));
}
```

- [ ] **Step 4: Verify it analyzes and runs on web**

Run:
```bash
cd example && flutter pub get && flutter analyze
```
Expected: `No issues found!`

Run (manual, leave running):
```bash
cd example && flutter run -d chrome
```
Expected: a 3-pane Storybook opens in Chrome. Manually confirm: sidebar lists Tokens/Structures; selecting "Colors" shows swatches; editing a hex in the right panel re-themes; the device dropdown reframes the stage; "Copy palette as Dart" puts text on the clipboard.

- [ ] **Step 5: Commit**

```bash
cd .. && git add example
git commit -m "feat(storybook): add standalone web/macOS example host"
```

---

## Task 14 (Phase C — episutra repo): episutra story set + entrypoint

> **Different repo, separate build cycle.** Do this in `/Users/aicoder/Documents/episutra/app/episutra_flutter` AFTER Phases A–B are committed in `qtpi_ui`. episutra already path-depends on `qtpi_ui` (Project 1), so `package:qtpi_ui/storybook.dart` is importable. This task may be promoted to its own plan.

**Files:**
- Create: `lib/design_system/storybook/episutra_stories.dart`
- Create: `lib/storybook_main.dart`
- Test: `test/design_system/storybook/episutra_stories_test.dart`

**Interfaces:**
- Consumes: `Story` (`package:qtpi_ui/storybook.dart`), episutra's `ThemeService` + signature widgets (`GlowTap`, `MembraneSurface`, `OrganismButton`, `EpisutraButton`, `EpisutraTextField`, `StreamingIndicator`).
- Produces: `List<Story> episutraStories()`; a `storybook_main.dart` entrypoint running `StorybookApp` with episutra's palette.

- [ ] **Step 1: Write the failing test**

```dart
// test/design_system/storybook/episutra_stories_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:episutra_flutter/design_system/storybook/episutra_stories.dart';

void main() {
  test('episutraStories exposes a Widgets category', () {
    final cats = episutraStories().map((s) => s.category).toSet();
    expect(cats, contains('Widgets'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/design_system/storybook/episutra_stories_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write the story set**

```dart
// lib/design_system/storybook/episutra_stories.dart
import 'package:flutter/material.dart';
import 'package:qtpi_ui/storybook.dart';
import '../widgets/widgets.dart'; // episutra signature widgets barrel

/// episutra's signature-widget catalog, viewed through the shared engine.
/// Each widget shown via StatesGrid where it has meaningful states.
List<Story> episutraStories() => [
      Story(
        category: 'Widgets',
        name: 'GlowTap',
        builder: (_) => StatesGrid(states: {
          'default': (_) => GlowTap(onTap: () {}, child: const Text('Tap me')),
        }),
      ),
      Story(
        category: 'Widgets',
        name: 'MembraneSurface',
        builder: (_) => MembraneSurface(
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Membrane'),
          ),
        ),
      ),
      Story(
        category: 'Widgets',
        name: 'EpisutraTextField',
        builder: (_) => StatesGrid(states: {
          'default': (_) => const SizedBox(
              width: 240, child: EpisutraTextField(hintText: 'Type…')),
          'disabled': (_) => const SizedBox(
              width: 240,
              child: EpisutraTextField(hintText: 'Disabled', enabled: false)),
        }),
      ),
    ];
```

> **Note for implementer:** the constructor params above (`GlowTap.onTap/child`, `MembraneSurface.child`, `EpisutraTextField.hintText/enabled`) are best-guesses from the audit — open each widget file under `lib/design_system/widgets/` and match its real constructor. Add stories for the remaining signature widgets (`OrganismButton`, `StreamingIndicator`, `WindowChrome`, `EpisutraButton`, `EpisutraIconButton`, `EpisutraFileChip`, `AdaptableSplit`) the same way. For any widget needing DI services, register light fakes in `storybook_main.dart` rather than the real service locator.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/design_system/storybook/episutra_stories_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the entrypoint**

```dart
// lib/storybook_main.dart
import 'package:flutter/material.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';
import 'design_system/primitives/episutra_palette.dart';
import 'design_system/storybook/episutra_stories.dart';

void main() {
  final theme = ThemeService(lightPalette: EpisutraPalette.primary);
  final controller = StorybookThemeController(theme);
  runApp(StorybookApp(
    controller: controller,
    themeBuilder: (c) => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: c.tokens['color1'],
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.tokens['color3'] ?? const Color(0xFF00C3FF),
        brightness: Brightness.dark,
      ),
    ),
    stories: [
      ...qtpiStories(controller.tokens),
      ...episutraStories(),
    ],
  ));
}
```

- [ ] **Step 6: Verify and run on web**

Run:
```bash
flutter analyze && flutter run -d chrome -t lib/storybook_main.dart
```
Expected: `No issues found!`, then the Storybook opens showing both qtpi_ui tokens and episutra's widgets. Manually confirm each signature-widget story renders and live color edits re-theme them.

- [ ] **Step 7: Commit (in the episutra repo)**

```bash
git add lib/design_system/storybook lib/storybook_main.dart test/design_system/storybook
git commit -m "feat(storybook): add episutra story set + standalone entrypoint"
```

---

## Self-Review

**Spec coverage:**
- §4.0 standalone web hosts, two-host split, no mounted route → Tasks 13 (qtpi_ui host), 14 (episutra host); mounted route omitted by design.
- §4.1 interface-driven core (`Story`, `ThemeController`) → Tasks 2, 4.
- §4.2 sidebar / stage / tools, states grid, chrome-in-plain-Flutter → Tasks 7, 11.
- §4.3 token galleries (colors, spacing); typography browse-only → Task 12 (colors + spacing). *Typography specimen story not yet a task* — see gap below.
- §4.4 palette editor, contrast, copy-as-Dart, dark toggle, device presets → Tasks 8, 10, 5, 11, 3/9.
- §4.4.1 `ScreenMetrics` seam → Task 1.
- §4.5 reuse vs new → reuse honored (no changes to ThemeService logic; UiScaler only gains `initFrom`).

**Gap found & resolved:** §4.3 calls for a **Typography** specimen gallery (each text style with a shared sample sentence). Add this as an extra story inside Task 12's `qtpiStories` — append a `Story(category: 'Tokens', name: 'Typography', …)` that renders a column of `Text('The quick brown fox', style: …)` for each of `displayLarge`…`labelSmall` from `Theme.of(context).textTheme`, each labeled. (Browse-only; no controls.) Implementer: add it alongside the Colors/Spacing stories using the same `Story` shape; no new mechanism. *(Not split into its own task — it is one more entry in an existing list, below the right-sizing threshold.)*

**Placeholder scan:** no TBD/TODO/"handle edge cases" present; every code step is complete. Two explicit "match the real constructor" notes (Tasks 12, 14) are deliberate guards against inventing signatures for code this plan cannot see — the engineer verifies against the actual widget files.

**Type consistency:** `ThemeController` members (`tokens`, `setToken`, `reset`, `isDark`, `devicePreset`, `paletteName`) are identical across Tasks 4, 8, 11. `DevicePreset` fields (`name`, `width`) and `.defaults` consistent across Tasks 3, 9, 11. `paletteToDart(Map, {name})`, `contrastRatio`/`contrastRating`, `groupStories`/`StoryCategory.name`/`.stories`, `FixedScreenMetrics(width)`/`UiScaler.initFrom` all used with the same signatures they are defined with.

---

## Execution Handoff

Plan complete. Two execution options:

1. **Subagent-Driven (recommended)** — a fresh subagent per task, two-stage review between tasks, fast iteration.
2. **Inline Execution** — execute tasks in this session with checkpoints for review.

Which approach?
