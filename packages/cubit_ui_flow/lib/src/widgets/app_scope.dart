import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns a set of disposable objects (Cubits, ChangeNotifiers) with one
/// teardown point. Register them with [own]; [dispose] releases them in
/// reverse registration order.
abstract class AppScope {
  final List<Object> _owned = <Object>[];
  bool _disposed = false;

  /// Whether [dispose] has run.
  bool get isDisposed => _disposed;

  /// Registers [value] to be released when this scope is disposed and
  /// returns it. A [BlocBase] is closed, a [ChangeNotifier] is disposed,
  /// anything else is ignored. If the scope is already disposed, the value
  /// is released immediately so it cannot leak.
  T own<T extends Object>(T value) {
    if (_disposed) {
      _release(value);
    } else {
      _owned.add(value);
    }
    return value;
  }

  /// Releases every owned value in reverse order. Calling it again is a
  /// no-op. If a release throws, the remaining values are still released and
  /// the first error is rethrown. Subclasses that override this must call `super.dispose()`.
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    Object? firstError;
    StackTrace? firstStack;
    for (final value in _owned.reversed) {
      try {
        _release(value);
      } catch (e, st) {
        firstError ??= e;
        firstStack ??= st;
      }
    }
    _owned.clear();
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }

  static void _release(Object value) {
    if (value is BlocBase<Object?>) {
      value.close();
    } else if (value is ChangeNotifier) {
      value.dispose();
    }
  }
}
