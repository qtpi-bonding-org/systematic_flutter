import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('retries a thrown error up to maxAttempts', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(maxAttempts: 3),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(calls, 3);
    expect(part.peek(), isA<PartFailed<int>>());
    expect(part.peek().attempts, 3);
    expect(part.peek().exhausted, isTrue);
  });

  test('stops retrying as soon as an attempt succeeds', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        if (calls < 2) throw StateError('boom');
        return 7;
      },
      retry: const RetryConfig<int>(maxAttempts: 3),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(part.peek().valueOrNull, 7);
    expect(calls, 2);
  });

  test('does not retry an error when retryOnError is false', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(maxAttempts: 3, retryOnError: false),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(calls, 1);
    expect(part.peek().attempts, 1);
  });

  test('retries a value the predicate rejects', () async {
    var calls = 0;
    final part = SnapshotPart<String>(
      name: 'existence',
      load: () async {
        calls++;
        return calls < 3 ? 'unknown' : 'exists';
      },
      retry: RetryConfig<String>(
        maxAttempts: 5,
        retryOnValue: (value) => value == 'unknown',
      ),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(part.peek().valueOrNull, 'exists');
    expect(part.peek().exhausted, isFalse);
    expect(calls, 3);
  });

  test('an exhausted value retry settles ready, exhausted, with the value',
      () async {
    var calls = 0;
    final part = SnapshotPart<String>(
      name: 'existence',
      load: () async {
        calls++;
        return 'unknown';
      },
      retry: RetryConfig<String>(
        maxAttempts: 3,
        retryOnValue: (value) => value == 'unknown',
      ),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(calls, 3);
    expect(part.peek(), isA<PartReady<String>>());
    expect(part.peek().valueOrNull, 'unknown');
    expect(part.peek().exhausted, isTrue,
        reason: 'the policy must be able to route to instanceUnverifiable');
    expect(part.peek().attempts, 3);
  });

  test('waits the configured delay between attempts', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(
        maxAttempts: 3,
        delay: Duration(milliseconds: 40),
      ),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, 1);

    await Future<void>.delayed(const Duration(milliseconds: 130));
    expect(calls, 3);
  });

  test('invalidate during a backoff wait cancels the chain', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(
        maxAttempts: 3,
        delay: Duration(milliseconds: 40),
      ),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, 1);

    part.invalidate();
    await Future<void>.delayed(const Duration(milliseconds: 130));

    expect(calls, 1,
        reason: 'the sleeping chain must not resume after invalidate');
  });

  test('dispose during a backoff wait cancels the chain', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(
        maxAttempts: 3,
        delay: Duration(milliseconds: 40),
      ),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, 1);

    part.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 130));

    expect(calls, 1,
        reason: 'the armed timer must become a no-op after dispose');
  });

  test('a first-try failure with no retry budget is not exhausted', () async {
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async => throw StateError('boom'),
      retry: const RetryConfig<int>(maxAttempts: 3, retryOnError: false),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(part.peek().attempts, 1);
    expect(part.peek().exhausted, isFalse);
  });

  test('invalidate resets the attempt counter', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(maxAttempts: 2),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(calls, 2);

    part.invalidate();
    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(calls, 4);
    expect(part.peek().attempts, 2);
  });
}
