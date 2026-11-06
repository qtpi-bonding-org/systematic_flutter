/// Service/repository-side error wrapping, the counterpart of `tryOperation`.
///
/// A repository or service turns whatever went wrong inside a method into one
/// typed domain exception, so the cubit's `tryOperation`, the exception key
/// mapper and the error inbox all see a stable type:
///
/// ```dart
/// Future<Note> create(Note note) => tryMethod(
///   () async => _dao.insert(note),
///   NoteException.new,
///   'create',
/// );
/// ```
///
/// What survives the wrap, and why it matters:
/// - The **original stack trace**, so the inbox points at the real failure and
///   not at the line inside [tryMethod].
/// - The **original type and exception**, inside a [SafeExceptionCause]. Its
///   `toString` prints the type only, so a message with user data never leaks
///   into a report. A bug (an `Error`) is wrapped too and stays visible as
///   `OTHER_<Type>` in the error code; it is not hidden.
/// - A domain exception that is already the target type passes through
///   untouched.
///
/// Rule of thumb: wrap where a layer owns a typed exception that a mapper or a
/// caller uses. A one-line pass-through (`=> _dao.delete(id)`) does not need
/// it. Never wrap a call that already throws a different, mapped domain
/// exception into yet another type: [tryMethod] only passes through its own
/// target type, so the inner one would no longer match the mapper.
library;

/// Implemented by a domain exception that wraps another failure. The error
/// code mapper walks [cause] to name the root cause, and reads [message] (a
/// developer-chosen method label, never user data) to name the step.
abstract interface class WrappedFailure {
  /// A short, developer-written label such as `login failed: SocketException`.
  String get message;

  /// The failure this one wraps, usually a [SafeExceptionCause].
  Object? get cause;
}

/// The diagnostic capsule [tryMethod] stores as the wrapped exception's cause.
///
/// It keeps the original exception and stack for debugging, but its
/// `toString` is only the type name, so logging or printing it cannot leak a
/// message that contains user data.
class SafeExceptionCause {
  const SafeExceptionCause(
    this.originalType,
    this.originalException,
    this.originalStack,
  );

  final Type originalType;
  final Object originalException;
  final StackTrace originalStack;

  @override
  String toString() => originalType.toString();
}

/// Runs [method] and converts any failure that is not already an [E] into one
/// through [wrapException], keeping the original stack trace.
///
/// [methodName] is a developer label used in the message
/// (`"<methodName> failed: <OriginalType>"`); it is not derived from user data.
Future<T> tryMethod<T, E extends Exception>(
  Future<T> Function() method,
  E Function(String message, [Object? cause]) wrapException,
  String methodName,
) async {
  try {
    return await method();
  } on E {
    rethrow;
  } catch (error, stackTrace) {
    final wrapped = wrapException(
      '$methodName failed: ${error.runtimeType}',
      SafeExceptionCause(error.runtimeType, error, stackTrace),
    );
    Error.throwWithStackTrace(wrapped, stackTrace);
  }
}

/// Returns [value], or throws a typed exception when it is null. Use instead
/// of the `!` operator for a clearer error.
T requireNonNull<T, E extends Exception>(
  T? value,
  String name,
  E Function(String message, [Object? cause]) wrapException,
) {
  if (value == null) {
    throw wrapException('$name is null');
  }
  return value;
}
