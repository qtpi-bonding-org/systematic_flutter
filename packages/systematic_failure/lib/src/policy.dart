import 'package:l10n_key_resolver/runtime.dart';

import 'bin.dart';
import 'exceptions.dart';
import 'failure.dart';

bool _defaultIsBug(Object error) => error is Error;

FailurePolicy? _configuredPolicy;

/// Configures how failures are classified and the generic user-facing key.
///
/// A custom [isBug] takes precedence over exception categories, including
/// [DomainException].
class FailurePolicy {
  const FailurePolicy({this.isBug = _defaultIsBug, required this.generic});

  final bool Function(Object) isBug;
  final L10nKey generic;
}

/// Installs the process-wide policy, normally during application startup.
void configureFailurePolicy(FailurePolicy p) {
  _configuredPolicy = p;
}

/// Returns the configured policy.
///
/// Classification itself remains usable before configuration; this getter does
/// not, because callers asking for the generic key must configure at startup.
FailurePolicy get failurePolicy =>
    _configuredPolicy ??
    (throw StateError(
      'Failure policy is not configured; call configureFailurePolicy at startup.',
    ));

/// Resets global configuration for tests.
void resetFailurePolicy() {
  _configuredPolicy = null;
}

/// Classifies an error without exposing its text.
Failure classify(Object error) {
  final policy = _configuredPolicy;
  if ((policy?.isBug ?? _defaultIsBug)(error)) {
    return const Failure(bin: Bin.bug);
  }
  if (error is DomainException) {
    return Failure(
      bin: Bin.domain,
      kind: error.kind.name,
      message: error.kind.message,
    );
  }
  if (error is EnvironmentException) {
    return Failure(bin: Bin.environment, message: error.message);
  }
  return const Failure(bin: Bin.environment);
}
