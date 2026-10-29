import 'dart:io';

import 'package:l10n_key_resolver/testing.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('guard_test'));
  tearDown(() => root.deleteSync(recursive: true));

  void write(String path, String body) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(body);
  }

  test('passes for generated code and L10nKeys use', () {
    write('lib/l10n/l10n_key_resolver.g.dart',
        "const k = L10nKey.generated('a');");
    write('lib/ui.dart', 'final l = L10nKeys.a;');
    expect(() => assertNoHandwrittenKeys(root.path), returnsNormally);
  });

  test('fails on a handwritten L10nKey.generated', () {
    write('lib/ui.dart', "final l = L10nKey.generated('a');");
    expect(
      () => assertNoHandwrittenKeys(root.path),
      throwsA(
        isA<StateError>()
            .having((e) => e.message, 'message', contains('lib/ui.dart:1')),
      ),
    );
  });

  test('fails on DataText outside the allowlist', () {
    write('lib/ui.dart', "final l = DataText('x');");
    expect(
        () => assertNoHandwrittenKeys(root.path), throwsA(isA<StateError>()));
  });

  test('DataText is fine in an allowed path', () {
    write('lib/data/adapters.dart', "final l = DataText('x');");
    expect(
      () => assertNoHandwrittenKeys(root.path, allow: ['lib/data/']),
      returnsNormally,
    );
  });

  test('ignores comments', () {
    write('lib/ui.dart', "// DataText('x') and L10nKey.generated('a')\n");
    expect(() => assertNoHandwrittenKeys(root.path), returnsNormally);
  });

  test('only scans .dart files and skips generated files', () {
    write('README.md', "DataText('x')");
    write('lib/a.freezed.dart', "DataText('x')");
    expect(() => assertNoHandwrittenKeys(root.path), returnsNormally);
  });
}
