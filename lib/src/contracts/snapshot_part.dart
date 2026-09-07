import 'dart:async';

import '../impl/evaluation_context.dart';
import 'part_state.dart';
import 'retry_config.dart';

/// One independently-refreshable fact behind a routing decision.
class SnapshotPart<T> {
  /// Creates a pull part, loaded via [load] on first read and cached.
  SnapshotPart({
    required this.name,
    required FutureOr<T> Function() load,
    RetryConfig<T>? retry,
    Object? Function()? cacheKey,
  })  : _load = load,
        _retry = retry ?? RetryConfig<T>(),
        _cacheKey = cacheKey,
        _observedRead = null,
        _state = PartLoading<T>(),
        _settled = false;

  /// Creates a part fixed at [value]. For tests and seeded policies.
  SnapshotPart.ready(this.name, T value)
      : _load = (() => value),
        _retry = RetryConfig<T>(),
        _cacheKey = null,
        _observedRead = null,
        _state = PartReady<T>(value, attempts: 1),
        _settled = true;

  /// Creates a part fixed in the loading state. For tests.
  SnapshotPart.loading(this.name)
      : _load = (() => throw StateError('seeded loading part never loads')),
        _retry = RetryConfig<T>(),
        _cacheKey = null,
        _observedRead = null,
        _state = PartLoading<T>(),
        _settled = true;

  /// Creates a part fixed in the failed state. For tests.
  SnapshotPart.failed(
    this.name, {
    required Object error,
    int attempts = 1,
    bool exhausted = true,
  })  : _load = (() => throw StateError('seeded failed part never loads')),
        _retry = RetryConfig<T>(),
        _cacheKey = null,
        _observedRead = null,
        _state = PartFailed<T>(
          error: error,
          attempts: attempts,
          exhausted: exhausted,
        ),
        _settled = true;

  /// Creates a push part fed by [changes], re-reading via [read] on every
  /// emission.
  SnapshotPart.observed({
    required this.name,
    required T Function() read,
    required Stream<void> changes,
  })  : _load = read,
        _retry = RetryConfig<T>(),
        _cacheKey = null,
        _observedRead = read,
        _state = PartReady<T>(read(), attempts: 1),
        _settled = true {
    _subscription = changes.listen((_) => _refreshObserved(read));
  }

  /// A stable identifier, used in logs and debugging.
  final String name;

  final FutureOr<T> Function() _load;
  final RetryConfig<T> _retry;
  final Object? Function()? _cacheKey;
  final T Function()? _observedRead;
  final List<void Function()> _listeners = <void Function()>[];

  PartState<T> _state;
  bool _settled;
  Object? _lastCacheKey;

  /// Guards against a superseded load landing after an [invalidate].
  int _epoch = 0;
  Future<void>? _inFlight;
  StreamSubscription<void>? _subscription;

  /// The current state, registering this part as a dependency.
  PartState<T> read() {
    EvaluationContext.current?.recordRead(this);
    _checkCacheKey();
    _ensureLoading();
    return _state;
  }

  /// The current state, without registering a dependency or starting a load.
  PartState<T> peek() => _state;

  /// Drops the cached answer and cancels any load in flight.
  ///
  /// An observed part re-reads its source synchronously instead.
  void invalidate() {
    final observedRead = _observedRead;
    if (observedRead != null) {
      _refreshObserved(observedRead);
      return;
    }
    _reset(notify: true);
  }

  /// Drops the cached answer and cancels any load in flight.
  ///
  /// [notify] is false when the caller is about to read the fresh state
  /// anyway. A cacheKey-triggered reset happens *inside* [read], which is
  /// itself usually inside a policy evaluation, and notifying there would
  /// wake the binding mid-evaluation for a change it is already observing.
  void _reset({required bool notify}) {
    _epoch++;
    _inFlight = null;
    _settled = false;
    _state = PartLoading<T>();
    if (notify) _notify();
  }

  /// Registers [listener], called whenever the state changes.
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Removes a previously added [listener].
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Drops all listeners and cancels any stream subscription.
  void dispose() {
    // Bumping the epoch is what stops a retry chain: _scheduleNext's timer
    // has already been armed, and only the epoch check makes it a no-op.
    _epoch++;
    _inFlight = null;
    _listeners.clear();
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
  }

  void _checkCacheKey() {
    final keyFn = _cacheKey;
    if (keyFn == null) return;
    final key = keyFn();
    if (_settled && key != _lastCacheKey) _reset(notify: false);
    _lastCacheKey = key;
  }

  void _ensureLoading() {
    if (_settled || _inFlight != null) return;
    _attempt(1);
  }

  void _attempt(int attempt) {
    final epoch = _epoch;
    final FutureOr<T> result;
    // Only the loader is guarded. Settling notifies listeners, and a listener
    // that throws must not be misreported as a load failure -- that swallowed
    // the binding's own unsettleable-policy error and let the loop continue.
    try {
      result = _load();
    } on Object catch (error) {
      _settleError(error, attempt, epoch);
      return;
    }
    if (result is Future<T>) {
      _inFlight = _awaitValue(result, attempt, epoch);
      return;
    }
    _settleValue(result, attempt, epoch);
  }

  Future<void> _awaitValue(Future<T> future, int attempt, int epoch) async {
    final T value;
    try {
      value = await future;
    } on Object catch (error) {
      if (epoch != _epoch) return;
      _settleError(error, attempt, epoch);
      return;
    }
    if (epoch != _epoch) return;
    _settleValue(value, attempt, epoch);
  }

  void _settleValue(T value, int attempt, int epoch) {
    final wantsRetry = _retry.shouldRetryValue(value);
    if (wantsRetry && attempt < _retry.maxAttempts) {
      _scheduleNext(attempt, epoch);
      return;
    }
    _finish(
      PartReady<T>(value, attempts: attempt, exhausted: wantsRetry),
      epoch,
    );
  }

  void _settleError(Object error, int attempt, int epoch) {
    if (_retry.retryOnError && attempt < _retry.maxAttempts) {
      _scheduleNext(attempt, epoch);
      return;
    }
    // Exhausted means a retry budget existed and is now spent -- not that
    // there was never one to spend. maxAttempts: 1, or retryOnError: false,
    // is a plain failure on the first try.
    final hadBudget = _retry.retryOnError && _retry.maxAttempts > 1;
    _finish(
      PartFailed<T>(
        error: error,
        attempts: attempt,
        exhausted: hadBudget && attempt >= _retry.maxAttempts,
      ),
      epoch,
    );
  }

  void _scheduleNext(int attempt, int epoch) {
    _inFlight = Future<void>.delayed(_retry.delayForAttempt(attempt)).then((_) {
      if (epoch != _epoch) return;
      _attempt(attempt + 1);
    });
  }

  void _finish(PartState<T> state, int epoch) {
    if (epoch != _epoch) return;
    _state = state;
    _settled = true;
    _inFlight = null;
    _notify();
  }

  void _refreshObserved(T Function() read) {
    _state = PartReady<T>(read(), attempts: 1);
    _notify();
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}
