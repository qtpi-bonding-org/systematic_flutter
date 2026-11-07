/// Test-only helpers for systematic_failure.
library;

import 'src/bin.dart';
import 'src/policy.dart';

export 'src/policy.dart' show resetFailurePolicy;

/// Asserts that [error] classifies into the expected stable category.
///
/// A [StateError] is thrown rather than importing a test framework, so this
/// helper remains usable by any Dart test runner.
void expectFailure(Object error, {required Bin bin, String? kind}) {
  final actual = classify(error);
  if (actual.bin != bin || actual.kind != kind) {
    throw StateError(
      'Expected failure bin=$bin kind=$kind, '
      'but classified as bin=${actual.bin} kind=${actual.kind}.',
    );
  }
}
