import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('loading is not settled and has no value', () {
    const state = PartLoading<int>();
    expect(state.isLoading, isTrue);
    expect(state.isSettled, isFalse);
    expect(state.valueOrNull, isNull);
    expect(state.attempts, 0);
    expect(state.exhausted, isFalse);
  });

  test('ready is settled and exposes its value', () {
    const state = PartReady<int>(7, attempts: 1);
    expect(state.isReady, isTrue);
    expect(state.isSettled, isTrue);
    expect(state.valueOrNull, 7);
    expect(state.attempts, 1);
  });

  test('an exhausted value retry is observable on PartReady', () {
    const state = PartReady<String>('unknown', attempts: 3, exhausted: true);
    expect(state.isReady, isTrue);
    expect(state.valueOrNull, 'unknown');
    expect(state.exhausted, isTrue,
        reason: 'the instanceUnverifiable route depends on this');
  });

  test('failed carries error, attempts, and exhaustion', () {
    const state = PartFailed<int>(error: 'boom', attempts: 3, exhausted: true);
    expect(state.isFailed, isTrue);
    expect(state.isSettled, isTrue);
    expect(state.valueOrNull, isNull);
    expect(state.error, 'boom');
    expect(state.attempts, 3);
  });

  test('a switch over the union is exhaustive without a default', () {
    String describe(PartState<int> state) => switch (state) {
          PartLoading<int>() => 'loading',
          PartReady<int>(value: final v) => 'ready:$v',
          PartFailed<int>(exhausted: final e) => 'failed:$e',
        };

    expect(describe(const PartLoading<int>()), 'loading');
    expect(describe(const PartReady<int>(1)), 'ready:1');
    expect(
      describe(const PartFailed<int>(error: 'x', attempts: 1, exhausted: false)),
      'failed:false',
    );
  });
}
