import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_failure/systematic_failure.dart';

final _now = DateTime.utc(2026, 11, 6);

ErrorBoxEntry _row(
  String id,
  Bin bin, {
  int ageDays = 0,
  int firstAgeDays = 0,
  bool sent = false,
}) =>
    ErrorBoxEntry(
      id: id,
      fingerprint: id,
      errorData: ErrorEntry(
        bin: bin,
        errorType: 'T',
        source: 'S',
        stackTrace: '',
        timestamp: _now,
      ),
      occurrenceCount: 1,
      firstOccurred: _now.subtract(Duration(days: firstAgeDays)),
      lastOccurred: _now.subtract(Duration(days: ageDays)),
      wasSent: sent,
    );

void main() {
  test('sent rows are pruned when pruneSent is on, kept when off', () {
    final rows = [_row('a', Bin.bug, sent: true), _row('b', Bin.bug)];
    expect(idsToPrune(rows, const RetentionPolicy(), _now), ['a']);
    expect(
      idsToPrune(rows, const RetentionPolicy(pruneSent: false), _now),
      isEmpty,
    );
  });

  test('age is per bin and measured from lastOccurred', () {
    final rows = [
      _row('domain-old', Bin.domain, ageDays: 15),
      _row('bug-same-age', Bin.bug, ageDays: 15),
      _row('env-old', Bin.environment, ageDays: 31),
      _row('recurring', Bin.environment, ageDays: 1, firstAgeDays: 100),
    ];
    expect(
      idsToPrune(rows, const RetentionPolicy(), _now)..sort(),
      ['domain-old', 'env-old'],
    );
  });

  test('a null maxAge keeps rows of that bin forever', () {
    final rows = [_row('a', Bin.bug, ageDays: 9999)];
    const p = RetentionPolicy(maxAge: {Bin.bug: null});
    expect(idsToPrune(rows, p, _now), isEmpty);
  });

  test('over the cap: sent first, then domain, then oldest', () {
    final rows = [
      _row('bug-new', Bin.bug, ageDays: 1),
      _row('bug-old', Bin.bug, ageDays: 5),
      _row('dom', Bin.domain, ageDays: 2),
      _row('sent-bug', Bin.bug, ageDays: 3, sent: true),
    ];
    const keepSent = RetentionPolicy(maxEntries: 3, pruneSent: false);
    expect(idsToPrune(rows, keepSent, _now), ['sent-bug']);
    const two = RetentionPolicy(maxEntries: 2, pruneSent: false);
    expect(idsToPrune(rows, two, _now)..sort(), ['dom', 'sent-bug']);
    const one = RetentionPolicy(maxEntries: 1, pruneSent: false);
    expect(
      idsToPrune(rows, one, _now)..sort(),
      ['bug-old', 'dom', 'sent-bug'],
    );
  });
}
