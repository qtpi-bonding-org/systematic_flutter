import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('no context is current outside track', () {
    expect(EvaluationContext.current, isNull);
  });

  test('track exposes the context and records reads', () {
    final context = EvaluationContext();
    final marker = Object();

    final result = EvaluationContext.track(context, () {
      EvaluationContext.current?.recordRead(marker);
      return 42;
    });

    expect(result, 42);
    expect(context.reads, contains(marker));
    expect(EvaluationContext.current, isNull);
  });

  test('track restores the previous context even when body throws', () {
    final outer = EvaluationContext();
    final inner = EvaluationContext();

    EvaluationContext.track(outer, () {
      expect(
        () => EvaluationContext.track(inner, () => throw StateError('x')),
        throwsStateError,
      );
      expect(EvaluationContext.current, same(outer));
    });

    expect(EvaluationContext.current, isNull);
  });

  test('tracking does not survive an async gap', () async {
    final context = EvaluationContext();
    final marker = Object();

    EvaluationContext.track(context, () {
      Future<void>.delayed(Duration.zero).then((_) {
        EvaluationContext.current?.recordRead(marker);
      });
      return null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      context.reads,
      isNot(contains(marker)),
      reason: 'this is why NavigationPolicy.decide() must be synchronous',
    );
  });

  test('a fresh context starts with no reads', () {
    expect(EvaluationContext().reads, isEmpty);
  });
}
