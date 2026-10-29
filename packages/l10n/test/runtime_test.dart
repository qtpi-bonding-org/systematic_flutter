import 'package:l10n_key_resolver/runtime.dart';
import 'package:test/test.dart';

void main() {
  group('L10nKey', () {
    test('equal key and equal args are equal with equal hash', () {
      const a = L10nKey.generated('a.b');
      const b = L10nKey.generated('a.b');
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      final p = L10nKey.generated('n', {'count': 2, 'name': 'x'});
      final q = L10nKey.generated('n', {'name': 'x', 'count': 2});
      expect(p, q);
      expect(p.hashCode, q.hashCode);
    });

    test('different key or args are not equal', () {
      expect(const L10nKey.generated('a'), isNot(const L10nKey.generated('b')));
      expect(
        L10nKey.generated('n', {'count': 1}),
        isNot(L10nKey.generated('n', {'count': 2})),
      );
      expect(
        L10nKey.generated('n', {'count': 1}),
        isNot(const L10nKey.generated('n')),
      );
    });

    test('is never equal to DataText with the same text', () {
      expect(const L10nKey.generated('a'), isNot(const DataText('a')));
    });
  });

  group('DataText', () {
    test('compares by value', () {
      expect(const DataText('x'), const DataText('x'));
      expect(const DataText('x').hashCode, const DataText('x').hashCode);
      expect(const DataText('x'), isNot(const DataText('y')));
    });
  });

  group('Label', () {
    test('switch over Label is exhaustive', () {
      String describe(Label l) => switch (l) {
            L10nKey(:final key) => 'key:$key',
            DataText(:final value) => 'data:$value',
          };
      expect(describe(const L10nKey.generated('k')), 'key:k');
      expect(describe(const DataText('v')), 'data:v');
    });
  });
}
