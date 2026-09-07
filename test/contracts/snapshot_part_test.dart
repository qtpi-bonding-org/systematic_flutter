import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('peek neither loads nor registers a dependency', () async {
    var calls = 0;
    final part = SnapshotPart<int>(name: 'p', load: () async {
      calls++;
      return 1;
    });

    expect(part.peek(), isA<PartLoading<int>>());
    await Future<void>.delayed(Duration.zero);
    expect(calls, 0);
  });

  test('a synchronous loader settles synchronously', () {
    final part = SnapshotPart<int>(name: 'p', load: () => 9);
    final state = part.read();
    expect(state, isA<PartReady<int>>(),
        reason: 'a known fact must not force a spurious Wait');
    expect(state.valueOrNull, 9);
  });

  test('an async loader settles after a microtask and caches', () async {
    var calls = 0;
    final part = SnapshotPart<int>(name: 'p', load: () async {
      calls++;
      return 1;
    });

    expect(part.read(), isA<PartLoading<int>>());
    await Future<void>.delayed(Duration.zero);
    expect(part.read().valueOrNull, 1);
    expect(part.read().valueOrNull, 1);
    expect(calls, 1);
  });

  test('concurrent reads share one in-flight load', () async {
    var calls = 0;
    final completer = Completer<int>();
    final part = SnapshotPart<int>(name: 'p', load: () {
      calls++;
      return completer.future;
    });

    part.read();
    part.read();
    part.read();
    completer.complete(5);
    await Future<void>.delayed(Duration.zero);

    expect(calls, 1);
    expect(part.read().valueOrNull, 5);
  });

  test('invalidate drops the answer and reloads on next read', () async {
    var calls = 0;
    final part = SnapshotPart<int>(name: 'p', load: () async => ++calls);

    part.read();
    await Future<void>.delayed(Duration.zero);
    expect(part.read().valueOrNull, 1);

    part.invalidate();
    expect(part.peek(), isA<PartLoading<int>>());
    part.read();
    await Future<void>.delayed(Duration.zero);
    expect(part.read().valueOrNull, 2);
  });

  test('invalidate cancels an in-flight load rather than letting it land',
      () async {
    final first = Completer<int>();
    var calls = 0;
    final part = SnapshotPart<int>(name: 'p', load: () {
      calls++;
      return calls == 1 ? first.future : Future<int>.value(2);
    });

    part.read();
    part.invalidate();
    first.complete(1);
    await Future<void>.delayed(Duration.zero);

    expect(part.peek(), isA<PartLoading<int>>(),
        reason: 'a superseded load must not resurrect the old answer');
  });

  test('a superseded load never overwrites a newer one', () async {
    final first = Completer<int>();
    final second = Completer<int>();
    var calls = 0;
    final part = SnapshotPart<int>(name: 'p', load: () {
      calls++;
      return calls == 1 ? first.future : second.future;
    });

    part.read();
    part.invalidate();
    part.read();

    second.complete(2);
    await Future<void>.delayed(Duration.zero);
    first.complete(1);
    await Future<void>.delayed(Duration.zero);

    expect(part.peek().valueOrNull, 2);
  });

  test('a cacheKey change self-invalidates on next read', () async {
    var key = 'a';
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async => ++calls,
      cacheKey: () => key,
    );

    part.read();
    await Future<void>.delayed(Duration.zero);
    expect(part.read().valueOrNull, 1);

    key = 'b';
    expect(part.read(), isA<PartLoading<int>>());
    await Future<void>.delayed(Duration.zero);
    expect(part.read().valueOrNull, 2);
  });

  test('invalidating one part leaves others untouched', () async {
    final a = SnapshotPart<int>(name: 'a', load: () => 1);
    final b = SnapshotPart<int>(name: 'b', load: () => 2);
    a.read();
    b.read();

    a.invalidate();

    expect(a.peek(), isA<PartLoading<int>>());
    expect(b.peek().valueOrNull, 2);
  });

  test('a thrown error becomes PartFailed', () async {
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async => throw StateError('nope'),
    );

    part.read();
    await Future<void>.delayed(Duration.zero);
    final state = part.read();
    expect(state, isA<PartFailed<int>>());
    expect(state.attempts, 1);
    expect(state.exhausted, isTrue);
  });

  test('listeners fire when the part settles and on invalidate', () async {
    var notifications = 0;
    final part = SnapshotPart<int>(name: 'p', load: () async => 1);
    part.addListener(() => notifications++);

    part.read();
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 1);

    part.invalidate();
    expect(notifications, 2);
  });

  test('read registers a dependency, peek does not', () {
    final part = SnapshotPart<int>(name: 'p', load: () => 1);
    final context = EvaluationContext();

    EvaluationContext.track(context, () {
      part.peek();
      expect(context.reads, isEmpty);
      part.read();
    });

    expect(context.reads, contains(part));
  });

  test('a throwing listener is not misreported as a load failure', () {
    final part = SnapshotPart<int>(name: 'p', load: () => 1);
    part.addListener(() => throw StateError('listener blew up'));

    expect(part.read, throwsStateError,
        reason: 'the listener error must surface, not be swallowed');
    expect(part.peek(), isA<PartReady<int>>(),
        reason: 'the load itself succeeded; only the listener failed');
    expect(part.peek().valueOrNull, 1);
  });

  test('seeding constructors produce fixed states without loading', () {
    expect(SnapshotPart<int>.ready('a', 3).peek().valueOrNull, 3);
    expect(SnapshotPart<int>.loading('b').peek(), isA<PartLoading<int>>());

    final failed = SnapshotPart<int>.failed('c', error: 'x').peek();
    expect(failed, isA<PartFailed<int>>());
    expect(failed.exhausted, isTrue);
  });

  test('dispose removes listeners', () async {
    var notifications = 0;
    final part = SnapshotPart<int>(name: 'p', load: () async => 1);
    part.addListener(() => notifications++);

    part.dispose();
    part.read();
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 0);
  });
}
