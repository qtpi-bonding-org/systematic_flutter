import 'bin.dart';
import 'policy.dart';

/// Describes an error for agent tool results and debug output.
///
/// This is the only error-to-text API. It is never for user-facing UI text or
/// the error inbox. Domain failures intentionally use their stable type/kind,
/// not their localized message.
String describeError(Object error) {
  final failure = classify(error);
  switch (failure.bin) {
    case Bin.bug:
      return '${error.runtimeType}: $error';
    case Bin.domain:
      return error.toString();
    case Bin.environment:
      return error.toString();
  }
}
