import 'package:l10n_generator/src/arb_checks.dart';
import 'package:l10n_generator/src/arb_parser.dart';
import 'package:test/test.dart';

List<ArbEntry> parse(Map<String, dynamic> arb) => ArbParser().parse(arb);

void main() {
  group('checkTemplate', () {
    test('two ARB keys with the same dot key is an error', () {
      // 'aB' and 'aB1' differ, but 'a_b' style keys can collide; use direct
      // entries to force the collision.
      final entries = [
        const ArbEntry(arbKey: 'oneTwo', dotKey: 'one.two', value: 'x'),
        const ArbEntry(arbKey: 'oneTwo2', dotKey: 'one.two', value: 'y'),
      ];
      final errors = checkTemplate(entries, generateDotKeys: true)
          .where((i) => i.severity == Severity.error)
          .toList();
      expect(errors.single.message, contains('one.two'));
    });

    test('a key that does not round-trip is a warning', () {
      final issues = checkTemplate(
        parse({'aBC': 'x'}), // a.b.c -> aBC round-trips
        generateDotKeys: true,
      );
      expect(issues, isEmpty);
      final lossy = checkTemplate(
        parse({'Abc': 'x'}), // abc -> abc: the leading capital is lost
        generateDotKeys: true,
      );
      expect(lossy.single.severity, Severity.warning);
      expect(lossy.single.message, contains('Abc'));
    });

    test('lossy check is skipped when dot keys are off', () {
      expect(
        checkTemplate(parse({'Abc': 'x'}), generateDotKeys: false),
        isEmpty,
      );
    });
  });

  group('checkLocale', () {
    final template = parse({
      'hello': 'Hello',
      'rows': 'Table with {count} {count, plural, =1{row} other{rows}}',
      'pair': '{a} and {b}',
    });

    test('identical key set passes', () {
      final issues = checkLocale(
          template,
          {
            'hello': 'Hola',
            'rows': 'Tabla con {count}',
            'pair': '{b} y {a}',
          },
          'app_es.arb');
      expect(issues, isEmpty);
    });

    test('a missing key is an error naming the file and key', () {
      final issues = checkLocale(
          template,
          {
            'hello': 'Hola',
            'rows': '{count}',
          },
          'app_es.arb');
      expect(issues.single.severity, Severity.error);
      expect(issues.single.message,
          allOf(contains('app_es.arb'), contains('pair')));
    });

    test('an extra key is a warning', () {
      final issues = checkLocale(
          template,
          {
            'hello': 'Hola',
            'rows': '{count}',
            'pair': '{a}{b}',
            'stale': 'x',
          },
          'app_es.arb');
      expect(issues.single.severity, Severity.warning);
      expect(issues.single.message, contains('stale'));
    });

    test('a translation may drop placeholders', () {
      final issues = checkLocale(
          template,
          {
            'hello': 'Hola',
            'rows': 'Tabla',
            'pair': '{a}',
          },
          'app_es.arb');
      expect(issues, isEmpty);
    });

    test('a placeholder the template lacks is an error', () {
      final issues = checkLocale(
          template,
          {
            'hello': 'Hola {name}',
            'rows': '{count}',
            'pair': '{a}{b}',
          },
          'app_es.arb');
      expect(issues.single.severity, Severity.error);
      expect(issues.single.message, allOf(contains('hello'), contains('name')));
    });

    test('metadata keys and @@locale are ignored', () {
      final issues = checkLocale(
          template,
          {
            '@@locale': 'es',
            'hello': 'Hola',
            'rows': '{count}',
            'pair': '{a}{b}',
            '@hello': {'description': 'x'},
          },
          'app_es.arb');
      expect(issues, isEmpty);
    });

    test('a malformed message is an error', () {
      final issues = checkLocale(
          template,
          {
            'hello': 'Hola {',
            'rows': '{count}',
            'pair': '{a}{b}',
          },
          'app_es.arb');
      expect(issues.single.severity, Severity.error);
    });
  });
}
