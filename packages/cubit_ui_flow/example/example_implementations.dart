// Example implementations for cubit_ui_flow library
// These are reference implementations that projects can copy and customize

import 'package:cubit_ui_flow/cubit_ui_flow.dart';

/// Base implementation of [IStateMessageMapper] that combines exception and domain mappers
class BaseStateMessageMapper<S extends IUiFlowState> implements IStateMessageMapper<S> {
  final IExceptionKeyMapper exceptionMapper;
  final IDomainStateKeyMapper<S> domainMapper;

  const BaseStateMessageMapper({
    required this.exceptionMapper,
    required this.domainMapper,
  });

  @override
  MessageKey? map(S state) {
    // First try domain-specific mapping
    final domainKey = domainMapper.map(state);
    if (domainKey != null) {
      return domainKey;
    }

    // If state has error, try exception mapping
    if (state.hasError && state.error != null) {
      return exceptionMapper.map(state.error!);
    }

    return null;
  }
}

/// Stand-in for the generated `L10nKeys` of `l10n_generator`. In an app this
/// class is generated from the ARB file; nothing hand-writes
/// `L10nKey.generated`.
abstract final class ExampleKeys {
  static const networkError = L10nKey.generated('error.network');
  static const timeoutError = L10nKey.generated('error.timeout');
  static const genericError = L10nKey.generated('error.generic');
}

/// Default implementation of [IExceptionKeyMapper]
class DefaultExceptionKeyMapper implements IExceptionKeyMapper {
  const DefaultExceptionKeyMapper();

  @override
  MessageKey? map(Object exception) {
    final message = exception.toString().toLowerCase();

    if (message.contains('network') || message.contains('connection')) {
      return const MessageKey.error(ExampleKeys.networkError);
    }

    if (message.contains('timeout')) {
      return const MessageKey.error(ExampleKeys.timeoutError);
    }

    return const MessageKey.error(ExampleKeys.genericError);
  }
}

/// Stand-in for the generated `L10nKeyResolver`: shows the key and arguments.
class FallbackLabelResolver implements LabelResolver {
  const FallbackLabelResolver();

  @override
  String resolve(Label label) => switch (label) {
        L10nKey(:final key, :final args) =>
          args.isEmpty ? key : '$key $args',
        DataText(:final value) => value,
      };
}
