import 'package:l10n_key_resolver/runtime.dart';

/// A domain-specific failure kind and its optional localized user message.
abstract interface class FailureKind implements Enum {
  L10nKey? get message;
}
