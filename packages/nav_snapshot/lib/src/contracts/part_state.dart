/// The resolution state of a single part.
sealed class PartState<T> {
  /// Creates a part state.
  const PartState({this.attempts = 0, this.exhausted = false});

  /// How many load attempts produced this state.
  final int attempts;

  /// Whether the retry budget is spent. The policy decides what that means.
  final bool exhausted;

  /// Whether the part is still resolving.
  bool get isLoading => this is PartLoading<T>;

  /// Whether the part resolved to a value.
  bool get isReady => this is PartReady<T>;

  /// Whether the part resolved to a failure.
  bool get isFailed => this is PartFailed<T>;

  /// Whether the part has finished resolving, successfully or not.
  bool get isSettled => !isLoading;

  /// The resolved value, or null when loading or failed.
  T? get valueOrNull => switch (this) {
        PartReady<T>(value: final value) => value,
        _ => null,
      };
}

/// The part has not resolved yet.
final class PartLoading<T> extends PartState<T> {
  /// Creates a loading state.
  const PartLoading({super.attempts});
}

/// The part resolved to [value].
final class PartReady<T> extends PartState<T> {
  /// Creates a ready state holding [value].
  const PartReady(this.value, {super.attempts, super.exhausted});

  /// The resolved value.
  final T value;
}

/// The part failed to resolve.
final class PartFailed<T> extends PartState<T> {
  /// Creates a failed state.
  const PartFailed({
    required this.error,
    super.attempts,
    super.exhausted,
  });

  /// The error from the last attempt.
  final Object error;
}
