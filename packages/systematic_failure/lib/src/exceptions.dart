import 'package:l10n_key_resolver/runtime.dart';

import 'failure_kind.dart';

/// An expected, domain-specific failure.
abstract class DomainException<K extends FailureKind> implements Exception {
  const DomainException({required this.kind});

  final K kind;

  @override
  String toString() => '$runtimeType.${kind.name}';
}

/// A failure caused by an external environment.
///
/// Applications may subclass this class and override [message].
class EnvironmentException implements Exception {
  const EnvironmentException();

  L10nKey? get message => null;
}
