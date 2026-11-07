// Example implementations for cubit_ui_flow library
// These are reference implementations that projects can copy and customize

import 'package:cubit_ui_flow/cubit_ui_flow.dart';

/// Stand-in for the generated `L10nKeys` of `l10n_generator`. In an app this
/// class is generated from the ARB file; nothing hand-writes
/// `L10nKey.generated`.
abstract final class ExampleKeys {
  static const networkError = L10nKey.generated('error.network');
  static const timeoutError = L10nKey.generated('error.timeout');
  static const genericError = L10nKey.generated('error.generic');
}

/// Stand-in for the generated `L10nKeyResolver`: shows the key and arguments.
class FallbackLabelResolver implements LabelResolver {
  const FallbackLabelResolver();

  @override
  String resolve(Label label) => switch (label) {
        L10nKey(:final key, :final args) => args.isEmpty ? key : '$key $args',
        DataText(:final value) => value,
      };
}
