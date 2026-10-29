import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:l10n_generator/builder.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

String arb(Map<String, dynamic> m) => jsonEncode(m);

const out = 'a|lib/l10n/l10n_key_resolver.g.dart';

Future<List<LogRecord>> run(
  Map<String, String> files, {
  Map<String, Object> options = const {},
  required bool expectOutput,
}) async {
  final logs = <LogRecord>[];
  await testBuilder(
    l10nKeyResolverBuilder(BuilderOptions(options)),
    files,
    outputs: expectOutput ? {out: isNotEmpty} : {},
    onLog: logs.add,
  );
  return logs;
}

Iterable<String> severe(List<LogRecord> logs) =>
    logs.where((l) => l.level >= Level.SEVERE).map((l) => l.message);

void main() {
  final en = arb({'hello': 'Hello', 'pair': '{a} and {b}'});

  test('single locale builds', () async {
    final logs = await run({'a|lib/l10n/app_en.arb': en}, expectOutput: true);
    expect(severe(logs), isEmpty);
  });

  test('complete locales build', () async {
    final logs = await run({
      'a|lib/l10n/app_en.arb': en,
      'a|lib/l10n/app_es.arb': arb({'hello': 'Hola', 'pair': '{a}'}),
    }, expectOutput: true);
    expect(severe(logs), isEmpty);
  });

  test('a locale missing a key fails the build', () async {
    final logs = await run({
      'a|lib/l10n/app_en.arb': en,
      'a|lib/l10n/app_es.arb': arb({'hello': 'Hola'}),
    }, expectOutput: false);
    expect(
        severe(logs).join(), allOf(contains('app_es.arb'), contains('pair')));
  });

  test('a locale with a placeholder the template lacks fails', () async {
    final logs = await run({
      'a|lib/l10n/app_en.arb': en,
      'a|lib/l10n/app_es.arb': arb({'hello': 'Hola {x}', 'pair': '{a}'}),
    }, expectOutput: false);
    expect(severe(logs).join(), contains('x'));
  });

  test('an extra key only warns', () async {
    final logs = await run({
      'a|lib/l10n/app_en.arb': en,
      'a|lib/l10n/app_es.arb':
          arb({'hello': 'Hola', 'pair': '{a}', 'stale': 'x'}),
    }, expectOutput: true);
    expect(severe(logs), isEmpty);
    expect(
      logs.where((l) => l.level == Level.WARNING).map((l) => l.message).join(),
      contains('stale'),
    );
  });

  test('strict_locales false downgrades locale errors to warnings', () async {
    final logs = await run({
      'a|lib/l10n/app_en.arb': en,
      'a|lib/l10n/app_es.arb': arb({'hello': 'Hola'}),
    }, options: {
      'strict_locales': false
    }, expectOutput: true);
    expect(severe(logs), isEmpty);
  });

  test('locale_pattern and arb_dir select the locale files', () async {
    final logs = await run({
      'a|lib/l10n/app_en.arb': en,
      'a|lib/l10n/other_es.arb': arb({'hello': 'Hola'}),
    }, expectOutput: true);
    expect(severe(logs), isEmpty);

    final custom = await run({
      'a|lib/l10n/app_en.arb': en,
      'a|lib/l10n/other_es.arb': arb({'hello': 'Hola'}),
    }, options: {
      'locale_pattern': 'other_*.arb'
    }, expectOutput: false);
    expect(severe(custom).join(), contains('other_es.arb'));
  });

  test('a malformed template message fails the build', () async {
    final logs = await run({
      'a|lib/l10n/app_en.arb': arb({'bad': 'Hi {name'}),
    }, expectOutput: false);
    expect(severe(logs).join(), contains('bad'));
  });

  test('output has no timestamp and is stable', () async {
    final r1 = await _generate({'a|lib/l10n/app_en.arb': en});
    final r2 = await _generate({'a|lib/l10n/app_en.arb': en});
    expect(r1, r2);
  });
}

Future<String> _generate(Map<String, String> files) async {
  String? result;
  await testBuilder(
    l10nKeyResolverBuilder(BuilderOptions.empty),
    files,
    outputs: {
      out: predicate<List<int>>((b) {
        result = utf8.decode(b);
        return true;
      })
    },
  );
  return result!;
}
