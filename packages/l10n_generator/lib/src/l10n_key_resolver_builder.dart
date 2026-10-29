import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'arb_checks.dart';
import 'arb_parser.dart';
import 'resolver_generator.dart';

/// Generates `L10nKeys` and `L10nKeyResolver` from the template ARB, and
/// checks every other locale file against it in the same pass.
class L10nKeyResolverBuilder implements Builder {
  final BuilderOptions options;

  L10nKeyResolverBuilder(this.options);

  String get _arbFile =>
      options.config['arb_file'] as String? ?? 'lib/l10n/app_en.arb';
  String get _outputFile =>
      options.config['output_file'] as String? ??
      'lib/l10n/l10n_key_resolver.g.dart';

  @override
  Map<String, List<String>> get buildExtensions => {
        _arbFile: [_outputFile],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final config = options.config;
    final generateDotKeys = config['generate_dot_keys'] as bool? ?? true;
    final strictLocales = config['strict_locales'] as bool? ?? true;
    final arbDir = config['arb_dir'] as String? ?? p.dirname(_arbFile);
    final localePattern = config['locale_pattern'] as String? ?? 'app_*.arb';

    final template = jsonDecode(await buildStep.readAsString(inputId))
        as Map<String, dynamic>;
    final List<ArbEntry> entries;
    try {
      entries = ArbParser().parse(template);
    } on FormatException catch (e) {
      throw StateError('${inputId.path}: ${e.message}');
    }

    final issues = <ArbIssue>[
      ...checkTemplate(entries, generateDotKeys: generateDotKeys),
    ];

    // Read through findAssets so editing or adding a locale re-runs this.
    final localeIds = await buildStep
        .findAssets(Glob(p.posix.join(arbDir, localePattern)))
        .where((id) => id != inputId)
        .toList()
      ..sort();
    for (final id in localeIds) {
      final locale = jsonDecode(await buildStep.readAsString(id))
          as Map<String, dynamic>;
      for (final issue in checkLocale(entries, locale, p.basename(id.path))) {
        issues.add(
          issue.severity == Severity.error && !strictLocales
              ? ArbIssue(Severity.warning, issue.message)
              : issue,
        );
      }
    }

    for (final i in issues.where((i) => i.severity == Severity.warning)) {
      log.warning(i.message);
    }
    final errors = issues.where((i) => i.severity == Severity.error).toList();
    if (errors.isNotEmpty) {
      throw StateError(errors.map((e) => e.message).join('\n'));
    }

    final generator = ResolverGenerator(
      localizationsClass:
          config['localizations_class'] as String? ?? 'AppLocalizations',
      localizationsImport: config['localizations_import'] as String? ??
          'app_localizations.dart',
      generateDotKeys: generateDotKeys,
    );
    await buildStep.writeAsString(
      AssetId(inputId.package, _outputFile),
      generator.generate(entries),
    );
    log.info('Generated ${entries.length} l10n keys to $_outputFile');
  }
}
