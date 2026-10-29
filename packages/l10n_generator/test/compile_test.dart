@Tags(['compile'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:l10n_generator/src/arb_checks.dart';
import 'package:l10n_generator/src/arb_parser.dart';
import 'package:l10n_generator/src/resolver_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Runs the generator on real app ARBs, produces the real
/// `app_localizations.dart` with `flutter gen-l10n`, and analyzes both
/// together. A wrong signature, type or argument order fails here.
void main() {
  final packageRoot = Directory.current.path;
  final runtimePath = p.normalize(p.join(packageRoot, '..', 'l10n'));

  for (final app in ['episutra', 'quanitya', 'pocketcoder']) {
    test('$app: generated keys compile against real gen_l10n output', () async {
      final dir = Directory(
        p.join(packageRoot, '.dart_tool', 'compile_check', app),
      )..createSync(recursive: true);
      final l10n = Directory(p.join(dir.path, 'lib', 'l10n'))
        ..createSync(recursive: true);
      for (final f in Directory(p.join(packageRoot, 'test', 'fixtures', app))
          .listSync()
          .whereType<File>()) {
        f.copySync(p.join(l10n.path, p.basename(f.path)));
      }
      File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('''
name: compile_check_$app
publish_to: none
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
  l10n_key_resolver:
    path: $runtimePath
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  generate: true
''');
      File(p.join(dir.path, 'l10n.yaml')).writeAsStringSync('''
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/l10n
synthetic-package: false
''');

      await _run('flutter', ['pub', 'get'], dir.path);
      await _run('flutter', ['gen-l10n'], dir.path);

      // Generate with the real code path.
      final template = jsonDecode(
        File(p.join(l10n.path, 'app_en.arb')).readAsStringSync(),
      ) as Map<String, dynamic>;
      final entries = ArbParser().parse(template);
      expect(
        checkTemplate(entries, generateDotKeys: true)
            .where((i) => i.severity == Severity.error),
        isEmpty,
      );
      for (final f in l10n.listSync().whereType<File>().where(
            (f) =>
                RegExp(r'app_\w+\.arb$').hasMatch(f.path) &&
                !f.path.endsWith('app_en.arb'),
          )) {
        final issues = checkLocale(
          entries,
          jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
          p.basename(f.path),
        ).where((i) => i.severity == Severity.error);
        expect(issues, isEmpty, reason: f.path);
      }
      File(p.join(l10n.path, 'l10n_key_resolver.g.dart')).writeAsStringSync(
        ResolverGenerator(
          localizationsClass: 'AppLocalizations',
          localizationsImport: 'app_localizations.dart',
        ).generate(entries),
      );

      // Parameter names, types and order must equal gen_l10n's signatures.
      final real = _signatures(
        File(p.join(l10n.path, 'app_localizations_en.dart')).readAsStringSync(),
      );
      for (final e in entries.where((e) => e.hasParameters)) {
        final want = e.placeholders.map((x) => '${x.dartType} ${x.name}');
        expect(
          real[e.arbKey],
          want.toList(),
          reason: 'signature of ${e.arbKey}',
        );
      }

      final analysis = await Process.run(
        'dart',
        ['analyze', '--fatal-infos', 'lib'],
        workingDirectory: dir.path,
      );
      expect(analysis.exitCode, 0, reason: '${analysis.stdout}');

      // Run it: every key resolves to exactly what gen_l10n returns.
      Directory(p.join(dir.path, 'test')).createSync();
      File(p.join(dir.path, 'test', 'resolve_test.dart')).writeAsStringSync(
        _runtimeTest(app, entries),
      );
      await _run('flutter', ['test'], dir.path);
    });
  }
}

String _runtimeTest(String app, List<ArbEntry> entries) {
  String sample(String type) => switch (type) {
        'int' => '2',
        'double' => '1.5',
        'num' => '2',
        'DateTime' => 'DateTime(2020, 1, 2)',
        _ => "'x'",
      };
  final b = StringBuffer()
    ..writeln(
        "import 'package:compile_check_$app/l10n/app_localizations.dart';")
    ..writeln(
        "import 'package:compile_check_$app/l10n/l10n_key_resolver.g.dart';")
    ..writeln("import 'package:flutter/widgets.dart';")
    ..writeln("import 'package:intl/date_symbol_data_local.dart';")
    ..writeln("import 'package:flutter_test/flutter_test.dart';")
    ..writeln("import 'package:l10n_key_resolver/runtime.dart';")
    ..writeln('void main() {')
    ..writeln("  setUpAll(() => initializeDateFormatting('en'));")
    ..writeln("  final l10n = lookupAppLocalizations(const Locale('en'));")
    ..writeln('  final r = L10nKeyResolver(l10n);')
    ..writeln("  test('every key resolves like gen_l10n', () {");
  for (final e in entries) {
    if (e.hasParameters) {
      final named =
          e.placeholders.map((x) => '${x.name}: ${sample(x.dartType)}');
      final pos = e.placeholders.map((x) => sample(x.dartType));
      b.writeln(
          '    expect(r.resolve(L10nKeys.${e.arbKey}(${named.join(', ')})), '
          'l10n.${e.arbKey}(${pos.join(', ')}), reason: \'${e.arbKey}\');');
    } else {
      b.writeln('    expect(r.resolve(L10nKeys.${e.arbKey}), l10n.${e.arbKey}, '
          'reason: \'${e.arbKey}\');');
    }
  }
  b
    ..writeln('  });')
    ..writeln("  test('DataText is shown as is', () {")
    ..writeln("    expect(r.resolve(const DataText('t')), 't');")
    ..writeln('  });')
    ..writeln("  test('unknown key reports then throws in debug', () {")
    ..writeln('    final seen = <String>[];')
    ..writeln("    const nope = L10nKey.generated('no.such.key');")
    ..writeln('    expect(() => L10nKeyResolver(l10n, onUnknownKey: seen.add)'
        '.resolve(nope), throwsStateError);')
    ..writeln("    expect(seen, ['no.such.key']);")
    ..writeln('  });')
    ..writeln('}');
  return b.toString();
}

/// Method name to its `Type name` parameters, from a generated
/// `app_localizations_xx.dart`.
Map<String, List<String>> _signatures(String source) {
  final out = <String, List<String>>{};
  for (final m in RegExp(r'^  String (\w+)\(([^)]*)\) \{', multiLine: true)
      .allMatches(source)) {
    out[m.group(1)!] = m
        .group(2)!
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return out;
}

Future<void> _run(String exe, List<String> args, String cwd) async {
  final r = await Process.run(exe, args, workingDirectory: cwd);
  if (r.exitCode != 0) {
    fail('$exe ${args.join(' ')} failed:\n${r.stdout}\n${r.stderr}');
  }
}
