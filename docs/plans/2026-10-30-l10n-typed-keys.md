# l10n: typed localized labels (plan, rev 2 after review)

Breaking changes are fine: every app pins an old ref and moves when ready. Today all apps pin the old standalone `dart_l10n_key_resolver` repo, so adoption also changes their git URL to `qtpi_flutter_system` with `path:`.

## Why

An accessible name that is a plain `String` can be English in a Spanish UI, and nothing stops a literal reaching a screen reader. Make the label types such that a literal cannot be passed where a localized label is required. Runtime data (a note title, a tool name) is still allowed, but only through an explicit, greppable type.

## What the review changed

- **Split into two packages.** `packages/l10n` (pub `l10n_key_resolver`) becomes the zero-dependency runtime: `Label`, `L10nKey`, `DataText`, `LabelResolver`, `KeyConverter`. A new `packages/l10n_generator` (pub `l10n_generator`) holds the builder, parser and `build`/`analyzer`/`path` dependencies, and stays a dev dependency. `cubit_ui_flow` and `ui` depend only on the runtime.
- **The parser is already wrong for plurals and selects.** `_placeholderPattern` treats ICU branch words as arguments: Quanitya `accessibilityDataTableRows` (`{count, plural, =1{row} other{rows}}`) generates `(int count, String row, String rows)`, but Flutter's signature is `(int count)`. Fix first, with a small ICU scanner that recognizes `{name}` and `{name, type, ...}` only and treats branch bodies as nested message text. Regression test uses the real entry.
- **Types must match gen_l10n:** `double` stays `double` (was `num`); undeclared or untyped placeholders are `Object`; an undeclared plural count is `num`; a select placeholder is `String`.
- **The round-trip rationale was false.** The generated switch uses the real ARB key, never `dotToCamelCase`. So: error only on two ARB keys mapping to the same dot key (effectively unreachable); warning for keys that do not round-trip, because the exported `KeyConverter` is lossy for them.
- **The locale check rule is a subset, not equality.** Other locales have no `@meta` blocks, so placeholder names come from message text; a translation may drop or reorder placeholders. Rule: names in a translation must be a subset of the template's. Missing key = error, extra key = warning. This adds, beyond `flutter gen-l10n`'s untranslated report, a build failure in the same pass.
- **Unknown key:** `StateError` in debug and tests, key text in release, plus an `onUnknownKey` hook.
- **Compile test uses real gen_l10n output**, not a hand-written fake.
- **No `Generated at` timestamp** in the header (committed `.g.dart` churn).
- **`lookup(String)` is dropped.** A raw-string door defeats the goal. Code holding a raw dot key (persisted keybinding labels, for example) must go through a typed lookup table it owns.

## Runtime library: `package:l10n_key_resolver/runtime.dart`

`sealed` forces `Label`, `L10nKey` and `DataText` into one library, so they live in `runtime.dart`. Generated code cannot extend them.

- `sealed class Label`
- `final class L10nKey extends Label` with `const L10nKey.generated(String key, [Map<String, Object> args = const {}])`. Equality is key plus deep map equality; hash uses `Object.hashAllUnordered`. Only non-parameterized keys are const-friendly; parameterized keys are generated static methods and are never const, so they cannot sit inside a `const MessageKey`.
- `final class DataText extends Label` with `const DataText(String value)`: user or runtime data, shown as is.
- `abstract interface class LabelResolver { String resolve(Label label); }`
- `typedef UnknownKeyHandler = void Function(String key)`.
- `generated` has to be public (Dart has no friend access). It is policed by a grep test, shipped as a reusable helper `assertNoHandwrittenKeys(root, allow: [...])` that fails on `L10nKey.generated(` outside `*.g.dart` and on `DataText(` outside an allowlist.

## Generator (`packages/l10n_generator`)

1. `ArbParser`: ICU scanner as above; placeholder types per the mapping above; takes parameter order from the template message text, with a compile-test case where metadata order differs from message order.
2. `L10nKeys`: `static const name = L10nKey.generated('dot.key');` for plain keys, `static L10nKey name({required int count, ...})` for parameterized ones.
3. `L10nKeyResolver implements LabelResolver`; `resolve(Label)`; `knownKeys`, `hasKey`, `arbToDotKey`, `dotToArbKey` stay. Header imports `package:l10n_key_resolver/runtime.dart`.
4. Locale completeness check with options `arb_dir` (resolved in the primary input's package), `locale_pattern` (default `app_*.arb`), `strict_locales` (default true). Locale files are read through `findAssets`, so editing or adding one re-runs the builder. A build_test covers adding a locale on a warm build.
5. `generate_dot_keys: false` keeps working: the key is the camelCase name.

## Tests

- `arb_parser_test`: new ICU cases (plural, select, nested, escapes), the real `accessibilityDataTableRows` regression, untyped and no-metadata placeholders, `double`.
- `resolver_generator_test`: output for fixtures; compile test against real `flutter gen-l10n` output for Episutra (388 keys), Quanitya (en plus es/fr/pt, 799) and Pocketcoder (1138), each copied into a fixture.
- `runtime_test`: equality/hash with equal and unequal args, `DataText`, unknown-key behavior.
- `builder_test` (build_test): missing key fails, extra warns, translation placeholder subset passes, mismatch fails, single-locale passes, Quanitya's four locales pass.
- `guard_test`: the grep helper on fixtures.

## Out of scope (later plans)

`cubit_ui_flow` (`MessageKey` and `ILocalizationService` take `Label`; the `*From(record)` factories and `translate(String)` break; Quanitya's 234 `final (key, args) = L10nKeys.x(...)` uses break), the `ui` package (`LabelScope`, `SpokenText` with `Label`, wrapper move; widgets must re-resolve on locale change), Episutra adoption, and the app pin changes.

## Done when

All tests pass in both packages, `dart analyze` clean, generated output for the three apps' real ARBs compiles against their real `app_localizations.dart`, the Quanitya plural regression is a named test, README rewritten. Commit in the framework repo; push only after the user's go-ahead.
