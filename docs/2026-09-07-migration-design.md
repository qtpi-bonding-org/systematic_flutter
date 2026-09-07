# flutter_lint_generator — migration design

Supersedes the `custom_lint`-based design in `2026-09-07-design.md` for
everything *architectural*; the individual rule semantics documented there
(what each rule flags, its default config) are still correct and are not
repeated here except where the new platform changes them.

## Why this exists

Three decisions made together, in order:

1. **`custom_lint` is a dead end for this repo.** Its latest release
   (0.8.1, over a year old) caps `analyzer` at `<9.0.0`. Verified live:
   `flutter pub get` in `pocketcoder_pro` with the custom_lint-based package
   wired in fails because `pocketbase_drift`'s pinned `drift_dev: ^2.33.0`
   requires `analyzer >=10.0.0`. There is no version of `custom_lint` that
   resolves against pocketcoder's real dependency graph.

2. **Migrate to Dart's first-party analyzer plugin system**
   (`analysis_server_plugin`, stable since Dart 3.10, actively released —
   latest version was published days before this was written). It has one
   real gap versus `custom_lint`: **no per-rule runtime configuration**,
   only `diagnostics: rule_name: true/false` enable/disable in
   `analysis_options.yaml`. Confirmed by reading `using_plugins.md` in the
   Dart SDK source directly — no key-value option-passing exists.

3. **Work around the config gap with codegen, not hardcoding.** A single
   generated file (`lib/generated_config.dart`) holds every rule's
   configurable values as top-level `const` declarations. A `bin/generate.dart`
   CLI renders that one file from a small YAML config
   (`lint_config.yaml`, same shape as the old `custom_lint:` block). All 13
   rule implementations are fixed, checked-in source that imports from
   `generated_config.dart` — nothing else about the package is templated.
   A different consuming project that wants different class names clones
   this repo separately and runs the generator with its own config; two
   projects can't share one physical checkout with two different
   configurations, which is an acceptable constraint given there is
   exactly one real consumer today.

Also merged in at the user's request, since it has the exact same
"stuck on dead custom_lint" problem: **`cubit_ui_flow_lints`'s 6 rules**
(from `my-libs/flutter_cubit_ui_flow/cubit_ui_flow_lints`), ported into
this package rather than kept as a second, separately-broken package.

Explicitly out of scope for this plan: wiring the generated plugin into
`pocketcoder_pro`'s `analysis_options.yaml`, and the `freezed`/`drift_dev`
major-version bump that integration depends on (`freezed: ^3.0.0` -> `^4.0.0`
was confirmed low-risk — pocketcoder has zero `@unfreezed` usage, the only
breaking change in freezed's entire 3.x->4.0.1 changelog — but the bump
itself is a different agent's task, not this one's).

## Platform API, verified against installed source

Verified directly against `~/.pub-cache/hosted/pub.dev/analyzer-14.3.0` and
`analysis_server_plugin-0.3.22` source (not doc summaries alone — a lesson
from the custom_lint build, where an unverified assumption cost a
fix-everywhere cycle across 6 already-written rules).

- Rule base class: `AnalysisRule` (`package:analyzer/analysis_rule/analysis_rule.dart`).
  Constructor: `super(name: '...', description: '...')`. Must override
  `LintCode get diagnosticCode`, backed by a `static const LintCode code =
  LintCode('rule_name', 'problem message', correctionMessage: '...')`.
- Visitor: a `_Visitor extends SimpleAstVisitor<void>`
  (`package:analyzer/dart/ast/visitor.dart`), constructed with
  `(AnalysisRule rule, RuleContext context)`. Registered in the rule's
  `void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext
  context)` via `registry.addXxx(this, visitor)` — one `add` call per AST
  node type the visitor overrides a `visitXxx` for.
- Reporting: `rule.reportAtNode(node)` (called on the rule instance itself,
  not a separate reporter object).
- Plugin: `class MyPlugin extends Plugin` (`package:analysis_server_plugin/plugin.dart`)
  with `String get name` and `void register(PluginRegistry registry)`
  (`package:analysis_server_plugin/registry.dart`), calling
  `registry.registerLintRule(MyRule())` once per rule. Entry point must be
  `lib/main.dart` with a top-level `final plugin = MyPlugin();`, and
  `pubspec.yaml` needs a `plugin: platforms: dart: {pluginClass:
  MyPlugin, fileName: main.dart}` section.
- Consumer wiring (for whoever does the pocketcoder integration later):
  `analysis_options.yaml` gets a top-level `plugins: <name>: {path: ...}`
  block, with `diagnostics: rule_name: true` per rule to enable it (lint
  rules are off by default; `registerWarningRule` instead of
  `registerLintRule` would make a rule on by default, but this package
  uses `registerLintRule` uniformly so every rule needs explicit
  enabling — deliberate, so a new consumer sees exactly what it's turning on).
- File path access (for path-scoped rules, e.g. `no_inline_widget_composition_in_pages`,
  `avoid_bloc_imports_in_widgets_dir`): `context.currentUnit?.file.path` or
  `context.definingUnit.file.path` (`RuleContextUnit.file` is an
  `analyzer` file-system `File`, with a `.path` string getter) — replaces
  `custom_lint`'s `resolver.path`.
- Testing: the `analyzer_testing` package's `AnalysisRuleTest` base class,
  used with `test_reflective_loader`'s `@reflectiveTest` +
  `defineReflectiveSuite`. Tests call `assertDiagnostics(sourceString,
  [lint(offset, length)])` or `assertNoDiagnostics(sourceString)` — no
  fixture files needed, source is an inline string. This replaces the old
  package's `test/fixtures/*.dart` + `testAnalyzeAndRun(File)` pattern
  entirely; delete the old fixture-file approach, don't try to keep both.

### AST shape deltas vs. analyzer 8.4.0 (what the old custom_lint rules used)

Found by reading analyzer 14.3.0 source directly, since a straight port of
the already-working custom_lint rule bodies silently breaks otherwise:

| Old (analyzer 8.4.0 / custom_lint) | New (analyzer 14.3.0) |
|---|---|
| `NamedExpression`, `.name.label.name`, `visitNamedExpression`, `addNamedExpression` | `NamedArgument`, `.name.lexeme` (`.name` is now a bare `Token`), `visitNamedArgument`, `addNamedArgument` |
| `NamedType.name2` (deprecated even at 8.4.0, alias for `.name`) | `name2` is **removed entirely** — use `.name` (a `Token`) |
| `ClassDeclaration.name` (a `Token`) | **Removed** — replaced by `ClassDeclaration.namePart.typeName` (a `Token`), part of new primary-constructor support |
| `resolver.path` (custom_lint `CustomLintResolver`) | `context.currentUnit?.file.path` / `context.definingUnit.file.path` |

Everything else used by the 13 rules being ported —
`InstanceCreationExpression`/`ConstructorName`/`.type`/`.name` (the
constructor-name identifier, unaffected), `PrefixedIdentifier`/`.prefix`/`.identifier`,
`MethodInvocation`/`.methodName`/`.target`, `ImportDirective`/`UriBasedDirective.uri.stringValue`,
`FunctionExpression`, `FunctionReference`, `ExpressionFunctionBody`,
`ListLiteral`, `SetOrMapLiteral`, `RecordLiteral`, `SimpleIdentifier`,
`IntegerLiteral`, `DoubleLiteral`, `PrefixExpression`, `StringLiteral`,
`BinaryExpression` — all confirmed present and unchanged in analyzer
14.3.0's source.

## Package layout

```
my-libs/flutter_lint_generator/
  pubspec.yaml                    # analysis_server_plugin 0.3.22, analyzer 14.3.0, plugin: section
  lib/
    main.dart                     # `final plugin = FlutterLintGeneratorPlugin();`
    generated_config.dart         # THE ONLY generated file -- rendered by bin/generate.dart
    src/
      rules/
        no_hardcoded_colors.dart
        no_hardcoded_font_size.dart
        no_hardcoded_font_family.dart
        no_raw_sizedbox_spacing.dart
        no_hardcoded_padding.dart
        no_inline_widget_composition_in_pages.dart
        no_hardcoded_strings.dart
        avoid_bloc_imports_in_widgets_dir.dart
        avoid_getit_in_adapters_dir.dart
        require_cubitfield_over_raw_bloc_apis.dart
        require_static_selector.dart
        cubit_field_selector_must_be_equatable.dart
        no_duplicate_cubitfield_keys.dart
  bin/
    generate.dart                 # reads lint_config.yaml, writes lib/generated_config.dart
  lint_config.yaml                # the config; defaults match pocketcoder's real names
  test/
    rules/                        # one AnalysisRuleTest per rule, inline-string sources
```

## The 13 rules (config values, ported unchanged in meaning)

From the original `flutter_ui_lints` design (see `2026-09-07-design.md` for
full rationale per rule — unchanged here except AST implementation):

1. `no_hardcoded_colors` — `bannedTypes` default `['Colors', 'AppPalette']`
2. `no_hardcoded_font_size` — no config
3. `no_hardcoded_font_family` — `allowedTypes` default `['AppFonts']`
4. `no_raw_sizedbox_spacing` — `allowedEnclosingClasses` default `['VSpace', 'HSpace']`
5. `no_hardcoded_padding` — no config
6. `no_inline_widget_composition_in_pages` — `pageSuffix` default `'Screen'`,
   `widgetDirNames` default `['widgets', 'adapters']`, `bannedWidgetNames`
   default the same 17-name list as before
7. `no_hardcoded_strings` — `allowedTypes` default `['MessageKey']`

From `cubit_ui_flow_lints` (see that package's `lib/cubit_ui_flow_lints.dart`
for the original custom_lint bodies being ported — no config on any of these
in the original, none added here):

8. `avoid_bloc_imports_in_widgets_dir` — flags an import of
   `flutter_bloc`/`get_it`/`injectable`/`go_router` in any file under a
   `widgets` directory.
9. `avoid_getit_in_adapters_dir` — flags an import of `get_it`/`injectable`
   in any file under an `adapters` directory.
10. `require_cubitfield_over_raw_bloc_apis` — flags `context.watch`/`context.select`
    calls and bare `BlocBuilder`/`BlocSelector`/`BlocConsumer` construction,
    outside a file named `cubit_adapter.dart`.
11. `require_static_selector` — flags a `cubitField(...)` call whose first
    argument is a `FunctionExpression` or `FunctionReference` (i.e. not a
    static/top-level tear-off).
12. `cubit_field_selector_must_be_equatable` — flags a `cubitField(...)`
    selector whose function-expression body is an expression that evaluates
    to a `ListLiteral`/`SetOrMapLiteral`/`RecordLiteral` (no stable value
    equality).
13. `no_duplicate_cubitfield_keys` — flags a second `cubitField(sameKey)`
    call within one file using a selector identifier already seen.

## Config file

`lint_config.yaml` at the package root (read by `bin/generate.dart`,
consumed nowhere else):

```yaml
no_hardcoded_colors:
  banned_types: [Colors, AppPalette]
no_hardcoded_font_family:
  allowed_types: [AppFonts]
no_raw_sizedbox_spacing:
  allowed_enclosing_classes: [VSpace, HSpace]
no_inline_widget_composition_in_pages:
  page_suffix: Screen
  widget_dir_names: [widgets, adapters]
  banned_widget_names: [Padding, Column, Row, Container, SizedBox, Text,
    Icon, Stack, ListView, GridView, Align, Center, Expanded, Flexible,
    Card, Scaffold, AppBar]
no_hardcoded_strings:
  allowed_types: [MessageKey]
```

Rules with no config (5 of the 7 design-system rules with no options, plus
all 6 cubit-flow rules) don't appear in the file at all — `generate.dart`
only ever emits `const` declarations for rules that actually have
configurable values.

`bin/generate.dart` writes `lib/generated_config.dart` as flat top-level
consts, e.g.:

```dart
// GENERATED -- do not edit by hand. Run `dart run bin/generate.dart`.
const noHardcodedColorsBannedTypes = ['Colors', 'AppPalette'];
const noHardcodedFontFamilyAllowedTypes = ['AppFonts'];
const noRawSizedboxSpacingAllowedEnclosingClasses = ['VSpace', 'HSpace'];
const noInlineWidgetCompositionInPagesPageSuffix = 'Screen';
const noInlineWidgetCompositionInPagesWidgetDirNames = ['widgets', 'adapters'];
const noInlineWidgetCompositionInPagesBannedWidgetNames = [
  'Padding', 'Column', /* ... */
];
const noHardcodedStringsAllowedTypes = ['MessageKey'];
```

Each configurable rule's `.dart` file does `import '../../generated_config.dart';`
and references its own constant directly in its constructor's default
field initializer — no `CustomLintConfigs`/`getLintRules(configs)`
indirection is needed anymore, since there's no runtime config to read.

`lib/generated_config.dart` is committed with the default (pocketcoder)
values already rendered, so the package works immediately with no
generation step required — `bin/generate.dart` only needs to be re-run by
a fork that wants different values.

## Testing

One `test/rules/<rule>_test.dart` per rule, using `analyzer_testing`'s
`AnalysisRuleTest` + `test_reflective_loader`. Inline source strings, no
fixture files. `bin/generate.dart` itself gets a plain unit test (given a
sample YAML string, does it produce the expected `generated_config.dart`
content) — no analyzer/AnalysisRule machinery needed for that one.

## Out of scope (unchanged from the original design, plus one addition)

- Everything from the original `2026-09-07-design.md`'s "Out of scope"
  section.
- Wiring the generated plugin into pocketcoder's `analysis_options.yaml`/
  `pubspec.yaml` (blocked on the `freezed`/`drift_dev` bump).
- The `freezed: ^3.0.0` -> `^4.0.0` and `drift_dev` bumps themselves --
  confirmed low-risk (zero `@unfreezed` usage in pocketcoder, so the one
  breaking change in freezed's 3.x->4.0.1 changelog doesn't apply) but
  assigned to a different agent, not this plan.
- Deleting `my-libs/flutter_cubit_ui_flow/cubit_ui_flow_lints` now that its
  rules live here too -- leave that decision and cleanup to whoever owns
  that package.
