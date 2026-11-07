import 'dart:io';

import 'package:l10n_key_resolver/runtime.dart';
import 'package:systematic_failure/systematic_failure.dart';
import 'package:systematic_failure/testing.dart';
import 'package:test/test.dart';

// Test-only key construction; production keys are generated.
L10nKey key(String value) => L10nKey.generated(value);

enum Kind implements FailureKind {
  missing,
  invalid;

  @override
  L10nKey? get message =>
      this == Kind.missing ? key('localized-message') : null;
}

class DomainFailure extends DomainException<Kind> {
  const DomainFailure(Kind kind) : super(kind: kind);
}

class NetworkFailure extends EnvironmentException {
  const NetworkFailure(this._message);
  final L10nKey _message;
  @override
  L10nKey get message => _message;
}

void main() {
  setUp(resetFailurePolicy);
  tearDown(resetFailurePolicy);

  test('classifies the three bins and ordinary exceptions', () {
    expect(classify(StateError('boom')), const Failure(bin: Bin.bug));
    expectFailure(DomainFailure(Kind.missing),
        bin: Bin.domain, kind: 'missing');
    expect(classify(NetworkFailure(key('offline'))),
        Failure(bin: Bin.environment, message: key('offline')));
    expect(classify(const FormatException('bad')),
        const Failure(bin: Bin.environment));
    expect(classify(Exception('bad')), const Failure(bin: Bin.environment));
    expect(classify('bad'), const Failure(bin: Bin.environment));
  });

  test('custom isBug wins over domain classification', () {
    configureFailurePolicy(FailurePolicy(
      generic: key('generic'),
      isBug: (error) => error is FormatException,
    ));
    expect(classify(const FormatException('bad')), const Failure(bin: Bin.bug));
    expect(classify(DomainFailure(Kind.invalid)),
        const Failure(bin: Bin.domain, kind: 'invalid'));
  });

  test('classification works before configuration', () {
    expect(classify(StateError('boom')).bin, Bin.bug);
    expect(classify(Exception('boom')).bin, Bin.environment);
  });

  test('policy getter and reset', () {
    expect(() => failurePolicy, throwsA(isA<StateError>()));
    final policy = FailurePolicy(generic: key('generic'));
    configureFailurePolicy(policy);
    expect(failurePolicy, same(policy));
    resetFailurePolicy();
    expect(() => failurePolicy, throwsA(isA<StateError>()));
  });

  test('domain exception has stable string form and generic enum works', () {
    expect(DomainFailure(Kind.missing).toString(), 'DomainFailure.missing');
    expect(Kind.missing.message, key('localized-message'));
    expect(DomainFailure(Kind.missing).kind, Kind.missing);
  });

  test('describeError uses the specified channel per bin', () {
    expect(describeError(StateError('boom')), 'StateError: Bad state: boom');
    expect(describeError(DomainFailure(Kind.missing)), 'DomainFailure.missing');
    expect(
        describeError(NetworkFailure(key('offline'))), contains('Instance of'));
    expect(describeError(DomainFailure(Kind.missing)),
        isNot(contains('localized-message')));
  });

  test('Failure equality includes all fields', () {
    expect(Failure(bin: Bin.domain, kind: 'x', message: key('x')),
        Failure(bin: Bin.domain, kind: 'x', message: key('x')));
    expect(Failure(bin: Bin.domain, kind: 'x'),
        isNot(Failure(bin: Bin.domain, kind: 'y')));
    expect(Failure(bin: Bin.domain, kind: 'x').hashCode,
        Failure(bin: Bin.domain, kind: 'x').hashCode);
  });

  test('core lib is pure Dart', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final line in entity.readAsLinesSync()) {
        if ((line.trimLeft().startsWith('import ') ||
                line.trimLeft().startsWith('export ')) &&
            line.contains('package:flutter/')) {
          offenders.add('${entity.path}: $line');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
