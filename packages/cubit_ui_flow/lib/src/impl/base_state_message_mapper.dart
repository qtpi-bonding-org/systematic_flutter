import '../contracts/all_contracts.dart';

/// Combines domain-state mapping with exception mapping.
class BaseStateMessageMapper<S extends IUiFlowState>
    implements IStateMessageMapper<S> {
  const BaseStateMessageMapper({
    required this.exceptionMapper,
    required this.domainMapper,
  });

  final IExceptionKeyMapper exceptionMapper;
  final IDomainStateKeyMapper<S> domainMapper;

  @override
  MessageKey? map(S state) {
    final domainKey = domainMapper.map(state);
    if (domainKey != null) return domainKey;
    if (state.error != null) return exceptionMapper.map(state.error!);
    return null;
  }
}
