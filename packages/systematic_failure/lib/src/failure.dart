import 'package:l10n_key_resolver/runtime.dart';

import 'bin.dart';

/// A classified failure, retaining only a stable kind and optional localized key.
class Failure {
  const Failure({required this.bin, this.kind, this.message});

  final Bin bin;
  final String? kind;
  final L10nKey? message;

  @override
  bool operator ==(Object other) =>
      other is Failure &&
      other.bin == bin &&
      other.kind == kind &&
      other.message == message;

  @override
  int get hashCode => Object.hash(bin, kind, message);

  @override
  String toString() => 'Failure(bin: $bin, kind: $kind, message: $message)';
}
