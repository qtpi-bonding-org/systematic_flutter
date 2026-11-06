import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_test/flutter_test.dart';

class _DomainException implements Exception, WrappedFailure {
  const _DomainException(this.message, [this.cause]);
  @override
  final String message;
  @override
  final Object? cause;
}

class _OtherException implements Exception {
  const _OtherException();
}

void main() {
  group('tryMethod', () {
    test('returns the value on success', () async {
      expect(
        await tryMethod(() async => 7, _DomainException.new, 'load'),
        7,
      );
    });

    test('rethrows the target exception type untouched', () async {
      const original = _DomainException('mine');
      await expectLater(
        tryMethod<int, _DomainException>(
          () async => throw original,
          _DomainException.new,
          'load',
        ),
        throwsA(same(original)),
      );
    });

    test('wraps a foreign failure in the target type, naming the method and '
        'only the original type', () async {
      try {
        await tryMethod<int, _DomainException>(
          () async => throw const _OtherException(),
          _DomainException.new,
          'load',
        );
        fail('should throw');
      } on _DomainException catch (e) {
        expect(e.message, 'load failed: _OtherException');
        expect(e.cause, isA<SafeExceptionCause>());
        final cause = e.cause! as SafeExceptionCause;
        expect(cause.originalType, _OtherException);
        expect(cause.originalException, isA<_OtherException>());
        // toString never leaks the original message.
        expect(cause.toString(), '_OtherException');
      }
    });

    test('keeps the original stack trace, not the rethrow site', () async {
      Never failingHelperForStack() => throw StateError('secret detail');
      try {
        await tryMethod<int, _DomainException>(
          () async => failingHelperForStack(),
          _DomainException.new,
          'load',
        );
        fail('should throw');
      } on _DomainException catch (_, stack) {
        expect(stack.toString(), contains('failingHelperForStack'));
      }
    });

    test('a bug (Error) is wrapped too, so it reaches the inbox with its '
        'original stack and type', () async {
      try {
        await tryMethod<int, _DomainException>(
          () async => throw StateError('boom'),
          _DomainException.new,
          'load',
        );
        fail('should throw');
      } on _DomainException catch (e) {
        expect(e.message, 'load failed: StateError');
        expect((e.cause! as SafeExceptionCause).originalException,
            isA<StateError>());
      }
    });
  });

  group('requireNonNull', () {
    test('returns a non-null value', () {
      expect(requireNonNull('x', 'key', _DomainException.new), 'x');
    });
    test('throws the typed exception when null', () {
      expect(
        () => requireNonNull<String, _DomainException>(
            null, 'key', _DomainException.new),
        throwsA(isA<_DomainException>()
            .having((e) => e.message, 'message', 'key is null')),
      );
    });
  });
}
