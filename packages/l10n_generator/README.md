# l10n_generator

A `build_runner` generator. From the template ARB (`app_en.arb`) it writes `l10n_key_resolver.g.dart` with:

- `L10nKeys`: one `L10nKey` per message. Plain keys are `static const`; parameterized keys are `static L10nKey name({required int count})`.
- `L10nKeyResolver implements LabelResolver`, calling the matching `AppLocalizations` member.

Dot keys come from the ARB key (`errorAuthFailed` becomes `error.auth.failed`). The generated switch always calls the real ARB getter, so a key that does not round-trip still resolves.

## Use

```yaml
dependencies:
  l10n_key_resolver:
    git: {url: <qtpi_flutter_system>, path: packages/l10n}
dev_dependencies:
  l10n_generator:
    git: {url: <qtpi_flutter_system>, path: packages/l10n_generator}
  build_runner: ^2.5.0
```

```yaml
# build.yaml
targets:
  $default:
    builders:
      l10n_generator:
        options:
          arb_file: lib/l10n/app_en.arb
          output_file: lib/l10n/l10n_key_resolver.g.dart
          localizations_import: app_localizations.dart
```

Other options: `localizations_class` (`AppLocalizations`), `generate_dot_keys` (`true`; `false` uses the camelCase key), `arb_dir`, `locale_pattern` (`app_*.arb`), `strict_locales` (`true`).

## Checks in the same pass

- Two ARB keys mapping to one dot key: error. A key that does not round-trip through `KeyConverter`: warning.
- Every other locale file: a missing key is an error, an extra key a warning, and a translation may use fewer placeholders than the template but never one the template lacks. `strict_locales: false` turns the errors into warnings.
- A malformed ICU message is an error naming the key.

## Argument types

They match `flutter gen-l10n`: a declared type wins (`double` stays `double`); undeclared is `Object`; an undeclared plural count is `num`; a select argument is `String`. Only `{name}` and `{name, type, ...}` introduce an argument; plural and select branch text is scanned for nested arguments, not mistaken for them. Parameter order is the order in the template message.

## Tests

`dart test` runs everything. The `compile` tag (in `test/compile_test.dart`) copies real ARBs from Episutra, Quanitya and Pocketcoder into a scratch Flutter project, runs `flutter gen-l10n`, compares signatures, runs `dart analyze`, and resolves every key against `AppLocalizations`. It needs `flutter` on the PATH and takes about a minute.
