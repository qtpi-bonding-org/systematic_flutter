import 'package:test/test.dart';
import 'package:l10n_generator/src/arb_parser.dart';

void main() {
  group('ArbParser', () {
    late ArbParser parser;

    setUp(() {
      parser = ArbParser();
    });

    test('parses simple string entries', () {
      final arb = {
        '@@locale': 'en',
        'errorTimeout': 'The operation timed out.',
        'successGeneric': 'Success!',
      };

      final entries = parser.parse(arb);

      expect(entries.length, 2);
      expect(entries[0].arbKey, 'errorTimeout');
      expect(entries[0].dotKey, 'error.timeout');
      expect(entries[0].value, 'The operation timed out.');
      expect(entries[0].hasParameters, false);
    });

    test('skips metadata keys starting with @', () {
      final arb = {
        '@@locale': 'en',
        'errorTimeout': 'Timeout',
        '@errorTimeout': {'description': 'Error message'},
      };

      final entries = parser.parse(arb);

      expect(entries.length, 1);
      expect(entries[0].arbKey, 'errorTimeout');
    });

    test('parses entries with placeholders', () {
      final arb = {
        'templateFieldsCount': '{count} Fields',
        '@templateFieldsCount': {
          'placeholders': {
            'count': {'type': 'int'},
          },
        },
      };

      final entries = parser.parse(arb);

      expect(entries.length, 1);
      expect(entries[0].hasParameters, true);
      expect(entries[0].placeholders.length, 1);
      expect(entries[0].placeholders[0].name, 'count');
      expect(entries[0].placeholders[0].dartType, 'int');
    });

    test('detects placeholders from a message without metadata', () {
      final arb = {'initializationReady': 'Ready at {ipAddress}'};

      final entries = parser.parse(arb);

      expect(entries, hasLength(1));
      expect(entries.single.hasParameters, isTrue);
      expect(entries.single.placeholders, hasLength(1));
      expect(entries.single.placeholders.single.name, 'ipAddress');
      expect(entries.single.placeholders.single.dartType, 'Object');
    });

    test('uses metadata type for a placeholder found in the message', () {
      final arb = {
        'retryAttempt': 'Attempt {attempt}',
        '@retryAttempt': {
          'placeholders': {
            'attempt': {'type': 'int'},
          },
        },
      };

      final entries = parser.parse(arb);

      expect(entries.single.placeholders.single.name, 'attempt');
      expect(entries.single.placeholders.single.dartType, 'int');
    });

    test('parses multiple placeholders', () {
      final arb = {
        'performanceWarning': 'Took {timeMs}ms. {suggestion}',
        '@performanceWarning': {
          'placeholders': {
            'timeMs': {'type': 'int'},
            'suggestion': {'type': 'String'},
          },
        },
      };

      final entries = parser.parse(arb);

      expect(entries[0].placeholders.length, 2);
      expect(entries[0].placeholders[0].name, 'timeMs');
      expect(entries[0].placeholders[0].dartType, 'int');
      expect(entries[0].placeholders[1].name, 'suggestion');
      expect(entries[0].placeholders[1].dartType, 'String');
    });

    test('extracts description from metadata', () {
      final arb = {
        'errorTimeout': 'Timeout',
        '@errorTimeout': {'description': 'Shown when operation times out'},
      };

      final entries = parser.parse(arb);

      expect(entries[0].description, 'Shown when operation times out');
    });

    test('sorts entries by dot key', () {
      final arb = {
        'zzzLast': 'Last',
        'aaaFirst': 'First',
        'mmmMiddle': 'Middle',
      };

      final entries = parser.parse(arb);

      expect(entries[0].dotKey, 'aaa.first');
      expect(entries[1].dotKey, 'mmm.middle');
      expect(entries[2].dotKey, 'zzz.last');
    });

    test('handles entries without metadata', () {
      final arb = {'simpleKey': 'Simple value'};

      final entries = parser.parse(arb);

      expect(entries.length, 1);
      expect(entries[0].description, null);
      expect(entries[0].placeholders, isEmpty);
    });
  });

  group('ArbParser ICU scanning', () {
    final parser = ArbParser();
    List<String> names(Map<String, dynamic> arb) =>
        parser.parse(arb).single.placeholders.map((p) => p.name).toList();

    test('Quanitya accessibilityDataTableRows: branch words are not arguments',
        () {
      final entries = parser.parse({
        'accessibilityDataTableRows':
            'Data table with {count} {count, plural, =1{row} other{rows}}',
        '@accessibilityDataTableRows': {
          'placeholders': {
            'count': {'type': 'int'},
          },
        },
      });
      final ph = entries.single.placeholders;
      expect(ph.map((p) => p.name), ['count']);
      expect(ph.single.dartType, 'int');
    });

    test('undeclared plural count is num', () {
      final ph = parser
          .parse({
            'items': '{n, plural, =0{none} other{many}}',
          })
          .single
          .placeholders;
      expect(ph.single.name, 'n');
      expect(ph.single.dartType, 'num');
    });

    test('select placeholder is String and branches are not arguments', () {
      final ph = parser
          .parse({
            'who': '{gender, select, male{He} female{She} other{They}}',
          })
          .single
          .placeholders;
      expect(ph.map((p) => p.name), ['gender']);
      expect(ph.single.dartType, 'String');
    });

    test('arguments nested in branches are found, in order', () {
      expect(
        names({
          'm': '{count, plural, =1{{name} has one} other{{name} has {count}}}',
        }),
        ['count', 'name'],
      );
    });

    test('quoted braces are literal', () {
      final entries = parser.parse({'lit': "Use '{braces}' and {real}"});
      expect(entries.single.placeholders.map((p) => p.name), ['real']);
    });

    test('doubled apostrophe is a literal apostrophe', () {
      final entries = parser.parse({'lit': "It''s {x}"});
      expect(entries.single.placeholders.map((p) => p.name), ['x']);
    });

    test('number, date and other formats name their argument', () {
      expect(
        names({'f': 'Cost {price, number, currency} on {when, date, short}'}),
        ['price', 'when'],
      );
    });

    test('declared double stays double', () {
      final ph = parser
          .parse({
            'ratio': '{value}',
            '@ratio': {
              'placeholders': {
                'value': {'type': 'double'},
              },
            },
          })
          .single
          .placeholders;
      expect(ph.single.dartType, 'double');
    });

    test('plural with offset', () {
      expect(
        names({'o': '{n, plural, offset:1 =0{nobody} other{# others}}'}),
        ['n'],
      );
    });

    test('unbalanced braces throw a FormatException naming the key', () {
      expect(
        () => parser.parse({'bad': 'Hello {name'}),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('bad'),
        )),
      );
    });
  });

  group('ArbPlaceholder', () {
    test('maps type to dartType correctly', () {
      expect(const ArbPlaceholder(name: 'n', type: 'int').dartType, 'int');
      expect(const ArbPlaceholder(name: 'n', type: 'integer').dartType, 'int');
      expect(
        const ArbPlaceholder(name: 'n', type: 'double').dartType,
        'double',
      );
      expect(const ArbPlaceholder(name: 'n', type: 'num').dartType, 'num');
      expect(
        const ArbPlaceholder(name: 'n', type: 'DateTime').dartType,
        'DateTime',
      );
      expect(
        const ArbPlaceholder(name: 'n', type: 'String').dartType,
        'String',
      );
      expect(
        const ArbPlaceholder(name: 'n', type: 'unknown').dartType,
        'Object',
      );
      expect(const ArbPlaceholder(name: 'n').dartType, 'Object');
      expect(
        const ArbPlaceholder(name: 'n', kind: ArbArgKind.plural).dartType,
        'num',
      );
      expect(
        const ArbPlaceholder(name: 'n', kind: ArbArgKind.select).dartType,
        'String',
      );
      expect(
        const ArbPlaceholder(
          name: 'n',
          type: 'int',
          kind: ArbArgKind.plural,
        ).dartType,
        'int',
      );
    });
  });
}
