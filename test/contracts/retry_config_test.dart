import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('defaults to a single attempt with no delay', () {
    const config = RetryConfig<int>();
    expect(config.maxAttempts, 1);
    expect(config.delay, Duration.zero);
    expect(config.retryOnError, isTrue);
    expect(config.retryOnValue, isNull);
  });

  test('fixed backoff returns the same delay for every attempt', () {
    const config = RetryConfig<int>(maxAttempts: 3, delay: Duration(seconds: 2));
    expect(config.delayForAttempt(1), const Duration(seconds: 2));
    expect(config.delayForAttempt(3), const Duration(seconds: 2));
  });

  test('exponential backoff doubles per attempt', () {
    const config = RetryConfig<int>(
      maxAttempts: 4,
      delay: Duration(seconds: 1),
      backoff: Backoff.exponential,
    );
    expect(config.delayForAttempt(1), const Duration(seconds: 1));
    expect(config.delayForAttempt(2), const Duration(seconds: 2));
    expect(config.delayForAttempt(3), const Duration(seconds: 4));
  });

  test('shouldRetryValue is false when no predicate is given', () {
    const config = RetryConfig<int>(maxAttempts: 3);
    expect(config.shouldRetryValue(1), isFalse);
  });

  test('shouldRetryValue consults the predicate', () {
    final config = RetryConfig<int>(
      maxAttempts: 3,
      retryOnValue: (value) => value == 0,
    );
    expect(config.shouldRetryValue(0), isTrue);
    expect(config.shouldRetryValue(1), isFalse);
  });
}
