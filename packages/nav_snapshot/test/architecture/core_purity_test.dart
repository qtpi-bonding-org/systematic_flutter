import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contracts and impl never import Flutter or go_router', () {
    final offenders = <String>[];

    for (final dir in ['lib/src/contracts', 'lib/src/impl']) {
      final directory = Directory(dir);
      if (!directory.existsSync()) continue;

      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        for (final line in entity.readAsLinesSync()) {
          final trimmed = line.trimLeft();
          if (!trimmed.startsWith('import ') &&
              !trimmed.startsWith('export ')) {
            continue;
          }
          if (trimmed.contains('package:flutter/') ||
              trimmed.contains('package:go_router/')) {
            offenders.add('${entity.path}: $trimmed');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Core must stay portable; adapters belong in lib/src/adapters.',
    );
  });

  test('contracts never imports impl except for evaluation_context', () {
    final offenders = <String>[];
    final directory = Directory('lib/src/contracts');

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      for (final line in entity.readAsLinesSync()) {
        final trimmed = line.trimLeft();
        if (!trimmed.startsWith('import ')) continue;
        if (trimmed.contains('../impl/') &&
            !trimmed.contains('evaluation_context.dart')) {
          offenders.add('${entity.path}: $trimmed');
        }
      }
    }

    expect(offenders, isEmpty);
  });
}
