/// Test helper: keep `L10nKey` and `DataText` construction where it belongs.
library;

import 'dart:io';

/// Throws a [StateError] (failing the calling test) when Dart files under [root] build an `L10nKey`
/// by hand (`L10nKey.generated(` outside `*.g.dart`) or create a `DataText`
/// outside the paths in [allow].
///
/// [allow] entries are path prefixes relative to [root], e.g. `lib/data/`.
/// Only `.dart` files are read; `*.g.dart` and `*.freezed.dart` are skipped
/// and `//` comments are ignored.
void assertNoHandwrittenKeys(String root, {List<String> allow = const []}) {
  final problems = <String>[];
  final rootDir = Directory(root);
  for (final f in rootDir.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    if (f.path.endsWith('.g.dart') || f.path.endsWith('.freezed.dart')) {
      continue;
    }
    final rel = f.path.substring(rootDir.path.length + 1);
    final allowed = allow.any(rel.startsWith);
    final lines = f.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final code = lines[i].split('//').first;
      if (code.contains('L10nKey.generated(')) {
        problems.add('$rel:${i + 1}: L10nKey.generated( outside a .g.dart');
      }
      if (!allowed && RegExp(r'\bDataText\(').hasMatch(code)) {
        problems.add('$rel:${i + 1}: DataText( outside the allowlist');
      }
    }
  }
  if (problems.isNotEmpty) {
    throw StateError(
      'Handwritten label construction:\n${problems.join('\n')}',
    );
  }
}
