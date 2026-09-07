/// How the delay between retry attempts grows.
enum Backoff {
  /// Every attempt waits [RetryConfig.delay].
  fixed,

  /// Attempt N waits `delay * 2^(N-1)`.
  exponential,
}

/// When and how often a pull part retries.
class RetryConfig<T> {
  /// Creates a retry configuration.
  const RetryConfig({
    this.maxAttempts = 1,
    this.delay = Duration.zero,
    this.backoff = Backoff.fixed,
    this.retryOnError = true,
    this.retryOnValue,
  });

  /// Total attempts, including the first. 1 means no retry.
  final int maxAttempts;

  /// Base delay between attempts.
  final Duration delay;

  /// How [delay] grows across attempts.
  final Backoff backoff;

  /// Whether a thrown error triggers a retry.
  final bool retryOnError;

  /// Whether a successfully returned value triggers a retry.
  final bool Function(T value)? retryOnValue;

  /// The delay before the given 1-based [attempt].
  Duration delayForAttempt(int attempt) {
    if (attempt <= 1 || backoff == Backoff.fixed) return delay;
    return delay * (1 << (attempt - 1));
  }

  /// Whether [value] should be retried rather than accepted.
  bool shouldRetryValue(T value) => retryOnValue?.call(value) ?? false;
}
