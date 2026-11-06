import 'dart:async';
import 'dart:io';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:flutter_test/flutter_test.dart';

class AuthException implements Exception, WrappedFailure {
  const AuthException(this.message, [this.cause]);
  @override
  final String message;
  @override
  final Object? cause;
}

class NoteException implements Exception, WrappedFailure {
  const NoteException(this.message, [this.cause]);
  @override
  final String message;
  @override
  final Object? cause;
}

Object wrapped(Object original) =>
    SafeExceptionCause(original.runtimeType, original, StackTrace.current);

void main() {
  final mapper = CauseChainErrorCodeMapper(
    codes: {'AuthException': 'AUTH_001', 'NoteException': 'NOTE_001'},
    steps: [('login', 'LOGIN'), ('save', 'SAVE')],
  );

  test('a bare mapped exception keeps its stable base code', () {
    expect(mapper.mapError(const AuthException('x')), 'AUTH_001');
  });

  test('an unmapped type falls back to ERR_<Type>', () {
    expect(mapper.mapError(StateError('x')), 'ERR_StateError');
  });

  test('adds a step from the developer-chosen method label', () {
    expect(mapper.mapError(const AuthException('login failed: X')),
        'AUTH_001.LOGIN');
  });

  test('the first matching step wins and message text is never copied', () {
    final code = mapper.mapError(const NoteException('save failed: secret@x'));
    expect(code, 'NOTE_001.SAVE');
    expect(code, isNot(contains('secret')));
  });

  test('names a DNS cause through a SafeExceptionCause', () {
    final e = AuthException(
        'login failed: SocketException',
        wrapped(const SocketException("Failed host lookup: 'a.example'")));
    expect(mapper.mapError(e), 'AUTH_001.LOGIN.DNS');
  });

  test('names other socket, tls and timeout causes', () {
    expect(
        mapper.mapError(AuthException(
            'login failed', wrapped(const SocketException('refused')))),
        'AUTH_001.LOGIN.UNREACHABLE');
    expect(
        mapper.mapError(AuthException('login failed',
            wrapped(TimeoutException(null, const Duration(seconds: 1))))),
        'AUTH_001.LOGIN.TIMEOUT');
    expect(
        mapper.mapError(AuthException(
            'login failed', wrapped(const HandshakeException('x')))),
        'AUTH_001.LOGIN.TLS');
  });

  test('a wrapped bug shows its type, so a TypeError is visible in the code',
      () {
    final e = NoteException('save failed: TypeError', wrapped(TypeError()));
    expect(mapper.mapError(e), 'NOTE_001.SAVE.OTHER_TypeError');
  });

  test('walks nested wrapper chains, bounded in depth', () {
    Object chain = const SocketException('x');
    for (var i = 0; i < 20; i++) {
      chain = NoteException('save failed', chain);
    }
    // Must terminate; depth limit stops the walk.
    expect(mapper.mapError(chain), startsWith('NOTE_001.SAVE'));
  });

  test('extraCause hook lets an app name its own causes', () {
    final custom = CauseChainErrorCodeMapper(
      codes: {'AuthException': 'AUTH_001'},
      extraCause: (error, depth) =>
          error is FormatException ? 'FORMAT' : null,
    );
    expect(
        custom.mapError(AuthException('x', wrapped(const FormatException()))),
        'AUTH_001.FORMAT');
  });

  test('a cause-less wrapper has no cause suffix', () {
    expect(mapper.mapError(const AuthException('x', null)), 'AUTH_001');
  });
}
