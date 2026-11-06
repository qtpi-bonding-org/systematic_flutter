import 'dart:async';
import 'dart:io';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';

/// Builds an error code of the form `BASE[.STEP][.CAUSE]`, for example
/// `AUTH_001.LOGIN.DNS`.
///
/// The inbox groups entries by error type, code and source, so each distinct
/// step and cause becomes its own row, and the code in a copied report says
/// what failed. Nothing from a message is copied into the code:
/// - `BASE` comes from [codes], keyed by the exception's type name.
/// - `STEP` is the first [steps] keyword found in the exception's
///   [WrappedFailure.message] (a developer-chosen label), mapped to a fixed token.
/// - `CAUSE` comes from the exception types in the cause chain.
///
/// An app provides its own [codes] table, and [extraCause] for exception types
/// from its own libraries (an HTTP client, a database).
class CauseChainErrorCodeMapper {
  const CauseChainErrorCodeMapper({
    required this.codes,
    this.steps = const [],
    this.extraCause,
    this.maxCauseDepth = 6,
  });

  /// Exception type name to a stable base code.
  final Map<String, String> codes;

  /// `(keyword, token)` pairs matched against the lowercase message; first
  /// match wins.
  final List<(String, String)> steps;

  /// Names a cause this package does not know. Return null to fall through.
  final String? Function(Object error, int depth)? extraCause;

  /// Bounds the walk through nested wrappers.
  final int maxCauseDepth;

  /// The code for [error]. Pass this method as the privserver's `errorCodeMapper`.
  String mapError(Object error) {
    final type = error.runtimeType.toString();
    final step = _step(error);
    final cause = _cause(error, 0);
    return [
      codes[type] ?? 'ERR_$type',
      if (step != null) step,
      if (cause != null) cause,
    ].join('.');
  }

  String? _step(Object error) {
    if (error is! WrappedFailure) return null;
    final message = error.message.toLowerCase();
    for (final (keyword, token) in steps) {
      if (message.contains(keyword)) return token;
    }
    return null;
  }

  String? _cause(Object error, int depth) {
    if (depth > maxCauseDepth) return null;
    if (error is WrappedFailure) {
      final inner = error.cause;
      return inner == null ? null : _cause(inner, depth + 1);
    }
    if (error is SafeExceptionCause) {
      return _cause(error.originalException, depth + 1);
    }
    final extra = extraCause?.call(error, depth);
    if (extra != null) return extra;
    return switch (error) {
      TimeoutException() => 'TIMEOUT',
      HandshakeException() || TlsException() || CertificateException() => 'TLS',
      SocketException(:final message)
          when message.toLowerCase().contains('host lookup') =>
        'DNS',
      SocketException() || HttpException() => 'UNREACHABLE',
      _ => depth == 0 ? null : 'OTHER_${error.runtimeType}',
    };
  }
}
