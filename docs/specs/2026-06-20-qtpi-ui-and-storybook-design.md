# qtpi_ui — Shared Design System + Native Storybook

**Date:** 2026-06-20
**Status:** design (awaiting review)
**Repos touched:** `qtpi_ui` (new), `episutra`, `quanitya`

---

## 1. Why this exists

Two Flutter apps already share a design system — but by *copy-paste-and-rename*, not by dependency:

- **quanitya** (`/Users/aicoder/Documents/openops/project/quanitya/public/quanitya_flutter`) — paused, beta-ready.
- **episutra** (`/Users/aicoder/Documents/episutra/app/episutra_flutter`) — active, UI not locked.

An audit of both `lib/design_system/` folders found **identical token + theme + structure code**, differing only by a `Quanitya`/`Episutra` class-name prefix. That is drift waiting to happen: a `UiScaler` fix in one app never reaches the other.

This project does two things, planned together but **implemented as two separate efforts**:

1. **`qtpi_ui` extraction** — pull the shared "bones" into one local package both apps depend on. Stops the drift.
2. **Storybook Engine** — a native-Flutter design tool (component catalog + live palette editor) built on the clean package.

**Timing rationale:** the extraction touches both apps' foundations. That is cheap now (quanitya paused, episutra unlocked) and expensive later (mid-beta). This is the window.

---

## 2. The shared / per-app boundary (evidence-based)

The split is not a guess — it is what already happened organically between the two apps.

| Layer | Lives in | Reusable? | Examples |
|---|---|---|---|
| **Token mechanism** | `qtpi_ui` | byte-identical today | `UiScaler` (393dp baseline, 0.85–1.15× clamp), `AppSizes` (8dp base), `VSpace`/`HSpace`, `AppPadding` |
| **Theme mechanism** | `qtpi_ui` | identical architecture | `ThemeService extends ChangeNotifier`, `AppColorPalette` wrapper, semantic-getter extension |
| **Structure primitives** | `qtpi_ui` | identical logic, renamed | `DsColumn` / `DsRow` / `DsGroup` (was `Episutra*` / `Quanitya*`) |
| **Storybook Engine** | `qtpi_ui` | 100% app-agnostic | sidebar / stage / tools, palette editor, contrast calc |
| — | — | — | — |
| **Palette *values* + fonts** | each app | brand identity — diverges | episutra navy `#0B152C` + cyan `#00C3FF`, Noto Mono; quanitya teal `#006280` + cream, Atkinson+Noto |
| **Signature widgets** | each app | each app's aesthetic | episutra: `GlowTap`, `MembraneSurface`, `AdaptableSplit`; quanitya: `zen_paper_background`, `notebook_fold`, `post_it_toast` |
| **Stories** | each app | travel with widgets | catalog entries describing each app's widgets |

**Rule of thumb:** the package owns the *machine* (how theming/spacing/scaling work); each app owns the *skin* (which colors, which fonts, which signature widgets).

---

## 3. Project 1 — `qtpi_ui` extraction

### 3.1 Home & consumption

- New repo at `/Users/aicoder/Documents/qtpi_ui` — **local git is sufficient**. Both apps consume it via a path dependency:
  ```yaml
  # episutra & quanitya pubspec.yaml
  dependencies:
    qtpi_ui:
      path: ../../../qtpi_ui   # relative path resolved per app
  ```
- A GitHub remote can be added later with zero code change.

### 3.2 What moves into the package

From each app's `lib/design_system/`:

- `primitives/`: `ui_scaler.dart`, `app_sizes.dart`, `app_spacings.dart`
- `theme/`: `theme_service.dart`, `app_theme.dart` builder, the `AppColorPalette` wrapper + semantic-getter extension
- `structures/`: `column.dart`, `row.dart`, `group.dart` → `DsColumn` / `DsRow` / `DsGroup`

Package exposes a single barrel: `package:qtpi_ui/qtpi_ui.dart`.

### 3.3 What stays per-app (does NOT move)

- **Palette values + fonts** — `episutra_palette.dart` (the `colors:{}` map), `episutra_fonts.dart`. Each app keeps its own.
- **Signature widgets** — everything in `widgets/` that encodes the app's look (`glow_tap.dart`, `membrane_surface.dart`, etc.).
- **Zen-grid / app-specific primitives** — `zen_grid_*`, `zen_grid_constants.dart` stay where used.

### 3.4 The "no rename" strategy — `typedef` aliases

Renaming every `EpisutraColumn(...)` call site is unnecessary churn. Dart class typedefs alias the shared class under each app's existing name:

```dart
// qtpi_ui:                class DsColumn extends StatelessWidget { ... }
// episutra aliases file:  typedef EpisutraColumn = DsColumn;
// quanitya aliases file:  typedef QuanityaColumn = DsColumn;
```

Every existing call site keeps compiling unchanged and constructs the shared `DsColumn`. Each app holds one small `lib/design_system/qtpi_aliases.dart`.

**Tokens need no aliasing at all** — `UiScaler`, `AppSizes`, `VSpace`, `AppPadding` are already neutral names; only their *import path* changes (one barrel import per file). `context.colors.primaryColor` is likewise untouched — the semantic-getter extension re-homes to the package, call sites don't move.

Net per-app churn: move files out → add barrel import → add one aliases file → fix import lines. **Mechanical, no logic edits, fully reviewable.**

### 3.5 Per-app palette injection

The package provides the *mechanism*; each app supplies its *values* at bootstrap:

```dart
// qtpi_ui: ThemeService holds a base palette + an override map (override map
// is empty in normal app runs; the Storybook populates it for live editing).
class ThemeService extends ChangeNotifier {
  ThemeService(this._basePalette);
  final IColorPalette _basePalette;
  final Map<String, Color> _overrides = {};       // empty in production
  IColorPalette get currentPalette => /* base + overrides */;
  // setOverride(key, color) / clearOverrides() drive live editing
}

// episutra bootstrap: getIt.registerSingleton(ThemeService(EpisutraPalette.primary));
```

This single override-map hook is what makes Project 2's live palette editing free.

### 3.6 Migration order (both apps, while quanitya is paused)

1. Scaffold `qtpi_ui` Flutter **package** (`flutter create --template=package`), move the bones in, expose barrel.
2. Migrate **episutra** first (active app, faster feedback): add path dep, aliases file, fix imports, delete moved files, `flutter analyze` + run.
3. Migrate **quanitya**: same steps. Verify it still builds/runs in its paused state.
4. Commit each repo independently.

### 3.7 Risks

- **Two-repo + new-repo blast radius.** Plan touches three repos; quanitya has its own git history. Named explicitly so it's not a surprise.
- **`flutter_color_palette` version skew** between the two apps. Pin one version in `qtpi_ui`; bump the lagging app if needed.
- **Const constructors / default params** that reference moved tokens — verify const-ness survives the move (typedef preserves it; spot-check `AppPadding` defaults).

---

## 4. Project 2 — Storybook Engine

Built **after** Project 1, on the clean package. Lives in `qtpi_ui` (engine is app-agnostic); each app contributes its own story set.

### 4.1 Interface-driven core (never imports an app)

```dart
class Story { final String category, name; final WidgetBuilder builder; }
abstract interface class ThemeController {        // backed by qtpi_ui ThemeService
  Map<String, Color> get tokens;
  void setToken(String key, Color value);
  void reset();
  bool get isDark; set isDark(bool v);
  double get scale; set scale(double v);
}
```

The Engine renders a `List<Story>` against a `ThemeController`. It knows nothing about `GlowTap` or `EpisutraPalette`.

### 4.2 Layout

- **Left sidebar** — categories → stories (Tokens / Widgets / Structures).
- **Center stage** — selected story rendered live on the real background, through real `UiScaler`. Widgets shown in a **states grid** (default · focused · disabled · error · loading where relevant).
- **Right tools panel** — global controls (below).

### 4.3 Token galleries (the "Tokens" category)

- **Colors** — every semantic token as a labeled swatch.
- **Typography** — each named text style (`displayLarge`…`labelSmall`) as a **specimen** with one shared sample sentence, to compare weight/size. (Browse-only; sizes are edited in code + hot-reload, not via sliders.)
- **Spacing / radii / icon sizes** — visual rulers/blocks.

### 4.4 Global tools (right panel)

1. **Full palette editor** — one picker per palette token, bound to `ThemeService` override map. Edit any token → whole stage re-themes live.
2. **Contrast calculator** — pick two tokens → WCAG ratio + AA/AAA pass-fail badge.
3. **Copy palette as Dart** — serialize the current (edited) palette back into the `colors:{}` literal to paste into the app's palette file. Closes the human-tweaks → code loop (the AI-agent-friendly path).
4. **Dark toggle** + **scale slider** (drives `UiScaler`) — sanity-check theme/responsive behavior.

### 4.5 Delivery

- Runnable **standalone** (the package's `example/` app) *and* mountable as a **`/storybook` dev route** inside any app (debug-only entry).
- Each app provides its story set; the Engine is shared.

---

## 5. Explicitly out of scope (YAGNI)

Deferred to a possible later "canvas" phase; the Story registry leaves room but we build none of it now:

- Drag-and-drop canvas / screen composition (the full Figma/Claude-Design replacement).
- Runtime editing of sizes/spacing (rarely changes → edit code + hot-reload).
- Theme persistence / export beyond "copy as Dart".
- Migrating quanitya's *signature* widgets or rebranding either app.

---

## 6. Build order

1. **Project 1 — `qtpi_ui` extraction** (now, quanitya paused). Stops drift; both apps on one package.
2. **Project 2 — Storybook Engine** (next, on the clean package). Serves both apps' story sets.

Each project gets its own implementation plan and its own build cycle.
