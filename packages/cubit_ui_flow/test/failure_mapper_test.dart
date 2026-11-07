import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n_key_resolver/runtime.dart';
import 'package:systematic_failure/systematic_failure.dart';

// Test-only stand-in for generated localization keys.
const _generic = L10nKey.generated('error.generic');
const _domain = L10nKey.generated('error.domain');
const _environment = L10nKey.generated('error.environment');

enum _Kind implements FailureKind {
  known(_domain),
  unknown(null);

  const _Kind(this.message);
  @override
  final L10nKey? message;
}

class _DomainError extends DomainException<_Kind> {
  const _DomainError(_Kind kind) : super(kind: kind);
}

class _EnvironmentError extends EnvironmentException {
  @override
  L10nKey get message => _environment;
}

class _State with UiFlowStateMixin {
  const _State({this.error});
  @override
  final Object? error;
  @override
  UiFlowStatus get status =>
      error == null ? UiFlowStatus.idle : UiFlowStatus.failure;
  @override
  IUiFlowState withLoading() => this;
  @override
  IUiFlowState withError(Object error) => _State(error: error);
}

class _DomainMapper implements IDomainStateKeyMapper<_State> {
  const _DomainMapper(this.key);
  final MessageKey? key;
  @override
  MessageKey? map(_State state) => key;
}

void main() {
  const mapper = ClassifyingExceptionKeyMapper(generic: _generic);

  test('classification uses stable keys and never error text', () {
    expect(mapper.map(const _DomainError(_Kind.known)).label, _domain);
    expect(mapper.map(const _DomainError(_Kind.unknown)).label, _generic);
    expect(mapper.map(_EnvironmentError()).label, _environment);
    expect(mapper.map(StateError('secret')).label, _generic);
    expect(mapper.map(FormatException('secret')).label, _generic);
    expect(mapper.map('secret').label, _generic);
    expect(
        mapper.map(StateError('secret')).toString(), isNot(contains('secret')));
  });

  test('domain mapper wins, then exception mapper, then null', () {
    const domainKey = MessageKey.success(_domain);
    const fallback = BaseStateMessageMapper<_State>(
      domainMapper: _DomainMapper(null),
      exceptionMapper: mapper,
    );
    const winning = BaseStateMessageMapper<_State>(
      domainMapper: _DomainMapper(domainKey),
      exceptionMapper: mapper,
    );
    expect(winning.map(_State(error: StateError('ignored'))), domainKey);
    expect(fallback.map(_State(error: StateError('failure')))?.label, _generic);
    expect(fallback.map(const _State()), isNull);
  });
}
