import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as path;

Future<List<AnalysisError>> lintFixture(
  DartLintRule rule,
  String fixtureFileName,
) {
  final fixturePath = path.join(
    Directory.current.path,
    'test',
    'fixtures',
    fixtureFileName,
  );
  return rule.testAnalyzeAndRun(File(fixturePath));
}
