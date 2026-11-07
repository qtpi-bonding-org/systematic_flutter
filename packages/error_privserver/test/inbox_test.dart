import 'dart:convert';

import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:flutter_error_privserver/src/inbox.dart';
import 'package:flutter_error_privserver/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_failure/systematic_failure.dart';

class _SlowStorage extends InMemoryErrorBoxStorage {
  @override
  Future<void> saveError(ErrorEntry error) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await super.saveError(error);
  }
}

class _FailingPruneStorage extends InMemoryErrorBoxStorage {
  bool failNext = true;
  @override
  Future<List<ErrorBoxEntry>> getAll() async {
    if (failNext) {
      failNext = false;
      throw StateError('prune read failed');
    }
    return super.getAll();
  }
}

ErrorInbox _inbox(ErrorBoxStorage s, {RetentionPolicy? retention}) =>
    ErrorInbox(s, retention ?? const RetentionPolicy(), const BuildInfo());

void main() {
  test('records the runtime type of an Error as a bug', () async {
    final s = InMemoryErrorBoxStorage();
    await _inbox(s)
        .record(StateError('secret'), StackTrace.current, source: 'C');
    final e = s.entries.single.errorData;
    expect(e.bin, Bin.bug);
    expect(e.errorType, 'StateError');
    expect(e.source, 'C');
  });

  test('a thrown String stores its type, never its text', () async {
    final s = InMemoryErrorBoxStorage();
    await _inbox(s).record('secret user text', StackTrace.current, source: 'C');
    final json = jsonEncode(s.entries.single.toJson());
    expect(s.entries.single.errorData.errorType, 'String');
    expect(json, isNot(contains('secret user text')));
  });

  test('concurrent records lose no rows', () async {
    final s = _SlowStorage();
    final inbox = _inbox(s);
    await Future.wait(<Future<void>>[
      for (var i = 0; i < 20; i++)
        inbox.record(FormatException('x'), StackTrace.current, source: 'S$i'),
    ]);
    expect(s.entries, hasLength(20));
  });

  test('a repeat of the same failure increments the count', () async {
    final s = InMemoryErrorBoxStorage();
    final inbox = _inbox(s);
    for (var i = 0; i < 3; i++) {
      await inbox.record(StateError('a'), StackTrace.current, source: 'C');
    }
    expect(s.entries.single.occurrenceCount, 3);
  });

  test('a failing prune does not break later records', () async {
    final s = _FailingPruneStorage();
    final inbox = _inbox(s);
    await inbox.record(StateError('a'), StackTrace.current, source: 'A');
    await inbox.record(StateError('b'), StackTrace.current, source: 'B');
    expect(s.entries, hasLength(2));
  });

  test('the cap is enforced after a save', () async {
    final s = InMemoryErrorBoxStorage();
    final inbox = _inbox(s, retention: const RetentionPolicy(maxEntries: 2));
    for (var i = 0; i < 4; i++) {
      await inbox.record(StateError('a'), StackTrace.current, source: 'S$i');
    }
    expect(s.entries, hasLength(2));
  });
}
