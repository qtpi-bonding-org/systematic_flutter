import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('is ready immediately, never loading', () {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'readiness',
      read: () => 1,
      changes: changes.stream,
    );

    expect(part.peek(), isA<PartReady<int>>());
    expect(part.peek().valueOrNull, 1);
  });

  test('re-reads on stream emission without passing through loading', () async {
    var value = 1;
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'readiness',
      read: () => value,
      changes: changes.stream,
    );

    final seen = <bool>[];
    part.addListener(() => seen.add(part.peek().isLoading));

    value = 2;
    changes.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(part.peek().valueOrNull, 2);
    expect(seen, everyElement(isFalse),
        reason: 'a known value must never flash through PartLoading');
  });

  test('notifies listeners on emission', () async {
    var notifications = 0;
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'p',
      read: () => 1,
      changes: changes.stream,
    );
    part.addListener(() => notifications++);

    changes.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 1);
  });

  test('invalidate re-reads synchronously and stays ready', () {
    var value = 1;
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'p',
      read: () => value,
      changes: changes.stream,
    );

    value = 5;
    part.invalidate();

    expect(part.peek(), isA<PartReady<int>>());
    expect(part.peek().valueOrNull, 5);
  });

  test('read registers a dependency', () {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'p',
      read: () => 1,
      changes: changes.stream,
    );
    final context = EvaluationContext();

    EvaluationContext.track(context, part.read);

    expect(context.reads, contains(part));
  });

  test('dispose cancels the subscription', () async {
    var reads = 0;
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'p',
      read: () {
        reads++;
        return 1;
      },
      changes: changes.stream,
    );

    final afterConstruction = reads;
    part.dispose();
    changes.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(reads, afterConstruction);
  });
}
