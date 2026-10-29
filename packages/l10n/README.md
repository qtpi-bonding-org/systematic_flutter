# l10n_key_resolver

Runtime types for typed localized labels. Zero dependencies. The code generator is the sibling package `l10n_generator` (a dev dependency).

## Why

An accessible name that is a plain `String` can be English in a Spanish UI. APIs that need a localized label take a `Label` instead, so a literal cannot be passed by accident:

```dart
sealed class Label
final class L10nKey extends Label   // a reference to an ARB message + args
final class DataText extends Label  // runtime data (a note title), shown as is
abstract interface class LabelResolver { String resolve(Label label); }
```

`import 'package:l10n_key_resolver/runtime.dart';`

- `L10nKey`s come only from the generated `L10nKeys`. `L10nKey.generated` is public because Dart has no friend access; the guard below polices it.
- Plain keys are `const`. Parameterized keys are static methods (`L10nKeys.rows(count: 3)`), never const.
- Equality is by key plus deep argument equality.
- `DataText` is the explicit, greppable escape hatch for data.

## Guard

```dart
import 'package:l10n_key_resolver/testing.dart';

test('no handwritten labels', () {
  assertNoHandwrittenKeys('lib', allow: ['lib/data/']);
});
```

Fails on `L10nKey.generated(` outside `*.g.dart`, and on `DataText(` outside the `allow` prefixes.

## Also here

`KeyConverter` converts between `error.auth.failed` and `errorAuthFailed`.

## Unknown keys

The generated resolver calls `onUnknownKey`, then throws `StateError` in debug and tests and returns the key text in release.
