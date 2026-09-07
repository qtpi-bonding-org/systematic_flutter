import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as path;

Future<List<AnalysisError>> lintFixture(
  DartLintRule rule,
  String fixtureFileName,
) {
  return rule.testAnalyzeAndRun(File(_fixturePath(fixtureFileName)));
}

/// 1-indexed line number of [error], read against the fixture's own source
/// -- `AnalysisError` (an alias for `Diagnostic` in this analyzer version)
/// exposes only a character [Diagnostic.offset], not a line number.
int lineNumberOf(AnalysisError error, String fixtureFileName) {
  final content = File(_fixturePath(fixtureFileName)).readAsStringSync();
  return LineInfo.fromContent(content).getLocation(error.offset).lineNumber;
}

String _fixturePath(String fixtureFileName) => path.join(
      Directory.current.path,
      'test',
      'fixtures',
      fixtureFileName,
    );
