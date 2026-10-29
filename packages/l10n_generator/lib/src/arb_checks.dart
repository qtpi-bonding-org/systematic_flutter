import 'package:l10n_key_resolver/l10n_key_resolver.dart';

import 'arb_parser.dart';

enum Severity { error, warning }

class ArbIssue {
  final Severity severity;
  final String message;

  const ArbIssue(this.severity, this.message);

  @override
  String toString() => '${severity.name}: $message';
}

/// Checks the template (primary) ARB: colliding or lossy dot keys.
///
/// The generated switch uses the real ARB key, so a lossy key still resolves;
/// only the exported [KeyConverter] helpers cannot map it back.
List<ArbIssue> checkTemplate(
  List<ArbEntry> entries, {
  required bool generateDotKeys,
}) {
  final issues = <ArbIssue>[];
  if (!generateDotKeys) return issues;

  final owner = <String, String>{};
  for (final e in entries) {
    final prev = owner[e.dotKey];
    if (prev != null) {
      issues.add(ArbIssue(
        Severity.error,
        'ARB keys "$prev" and "${e.arbKey}" both map to dot key "${e.dotKey}"',
      ));
    } else {
      owner[e.dotKey] = e.arbKey;
    }
    if (KeyConverter.dotToCamelCase(e.dotKey) != e.arbKey) {
      issues.add(ArbIssue(
        Severity.warning,
        'ARB key "${e.arbKey}" does not round-trip through KeyConverter '
        '(dot key "${e.dotKey}")',
      ));
    }
  }
  return issues;
}

/// Checks one other locale against the template.
///
/// A missing key is an error, an extra key a warning. A translation may use
/// fewer placeholders than the template (other locales carry no metadata, and
/// a language may not need every one) but never one the template lacks.
List<ArbIssue> checkLocale(
  List<ArbEntry> template,
  Map<String, dynamic> localeArb,
  String fileName,
) {
  final issues = <ArbIssue>[];
  final List<ArbEntry> entries;
  try {
    entries = ArbParser().parse(localeArb);
  } on FormatException catch (e) {
    return [ArbIssue(Severity.error, '$fileName: ${e.message}')];
  }
  final byKey = {for (final e in entries) e.arbKey: e};
  final templateKeys = {for (final e in template) e.arbKey};

  for (final t in template) {
    final e = byKey[t.arbKey];
    if (e == null) {
      issues.add(ArbIssue(
        Severity.error,
        '$fileName is missing key "${t.arbKey}"',
      ));
      continue;
    }
    final allowed = t.placeholders.map((p) => p.name).toSet();
    final extra = e.placeholders.map((p) => p.name).where(
          (n) => !allowed.contains(n),
        );
    if (extra.isNotEmpty) {
      issues.add(ArbIssue(
        Severity.error,
        '$fileName key "${t.arbKey}" uses placeholder(s) '
        '${extra.join(', ')} the template does not have',
      ));
    }
  }
  for (final e in entries) {
    if (!templateKeys.contains(e.arbKey)) {
      issues.add(ArbIssue(
        Severity.warning,
        '$fileName has key "${e.arbKey}" that the template does not',
      ));
    }
  }
  return issues;
}
