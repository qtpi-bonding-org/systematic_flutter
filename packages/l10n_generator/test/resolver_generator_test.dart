import 'package:l10n_generator/src/arb_parser.dart';
import 'package:l10n_generator/src/resolver_generator.dart';
import 'package:test/test.dart';

String gen(Map<String, dynamic> arb, {bool dotKeys = true}) =>
    ResolverGenerator(
      localizationsClass: 'AppLocalizations',
      localizationsImport: 'app_localizations.dart',
      generateDotKeys: dotKeys,
    ).generate(ArbParser().parse(arb));

void main() {
  group('header', () {
    test('imports the runtime and the localizations, with no timestamp', () {
      final code = gen({});
      expect(code, contains('// GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(code, contains("import 'package:l10n_key_resolver/runtime.dart';"));
      expect(code, contains("import 'app_localizations.dart';"));
      expect(code, isNot(contains('Generated at')));
    });

    test('output is identical across runs', () {
      final arb = {'a': 'A', 'bCount': '{n}'};
      expect(gen(arb), gen(arb));
    });
  });

  group('L10nKeys', () {
    test('plain key is a const L10nKey', () {
      expect(
        gen({'errorTimeout': 'Timeout'}),
        contains(
          "static const errorTimeout = L10nKey.generated('error.timeout');",
        ),
      );
    });

    test('parameterized key is a static method with named required args', () {
      final code = gen({
        'templateFieldsCount': '{count} Fields',
        '@templateFieldsCount': {
          'placeholders': {
            'count': {'type': 'int'},
          },
        },
      });
      expect(
        code,
        contains(
          'static L10nKey templateFieldsCount({required int count}) => '
          "L10nKey.generated('template.fields.count', {'count': count});",
        ),
      );
    });

    test('undeclared placeholder is Object, plural count is num', () {
      final code = gen({
        'who': 'Hi {name}',
        'rows': '{n, plural, =1{row} other{rows}}',
      });
      expect(code, contains('static L10nKey who({required Object name})'));
      expect(code, contains('static L10nKey rows({required num n})'));
    });

    test('generateDotKeys false uses the arb key', () {
      expect(
        gen({'errorTimeout': 'T'}, dotKeys: false),
        contains("L10nKey.generated('errorTimeout')"),
      );
    });
  });

  group('L10nKeyResolver', () {
    test('implements LabelResolver and resolves both label kinds', () {
      final code = gen({'errorTimeout': 'T'});
      expect(code, contains('class L10nKeyResolver implements LabelResolver {'));
      expect(code, contains('String resolve(Label label)'));
      expect(code, contains('DataText(:final value) => value'));
    });

    test('has no raw-string lookup', () {
      expect(gen({'a': 'A'}), isNot(contains('String? resolve(')));
    });

    test('switch uses the real ARB key for the getter', () {
      final code = gen({'errorTimeout': 'T'});
      expect(code, contains("'error.timeout' => _l10n.errorTimeout,"));
    });

    test('parameterized call casts args in message order', () {
      final code = gen({
        'greet': '{greeting} {name}',
        '@greet': {
          'placeholders': {
            'name': {'type': 'String'},
            'greeting': {'type': 'String'},
          },
        },
      });
      expect(
        code,
        contains(
          "'greet' => _l10n.greet(args['greeting'] as String, "
          "args['name'] as String),",
        ),
      );
    });

    test('unknown key reports, throws in debug, returns the key text', () {
      final code = gen({'a': 'A'});
      expect(code, contains('onUnknownKey?.call(key);'));
      expect(code, contains('assert(isDebug = true);'));
      expect(code, contains("throw StateError('Unknown l10n key: \$key');"));
      expect(code, contains('return key;'));
    });

    test('exposes knownKeys, hasKey and key maps', () {
      final code = gen({'errorTimeout': 'T'});
      expect(code, contains("'error.timeout',"));
      expect(code, contains('static bool hasKey(String key)'));
      expect(code, contains("'errorTimeout': 'error.timeout',"));
      expect(code, contains("'error.timeout': 'errorTimeout',"));
    });
  });
}
