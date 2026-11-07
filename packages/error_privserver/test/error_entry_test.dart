import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:systematic_failure/systematic_failure.dart';

void main() {
  test('round trips and builds report JSON', () {
    final time = DateTime.utc(2025, 1, 1);
    final entry = ErrorEntry.fromFailure(
      const Failure(bin: Bin.domain, kind: 'validation'),
      errorType: 'FormatException',
      source: 'TestCubit',
      stackTrace: 'stack',
      timestamp: time,
      buildInfo: const BuildInfo(appVersion: '1.0', commit: 'abc'),
    );
    expect(ErrorEntry.fromJson(entry.toJson()), entry);
    expect(entry.toReportJson()['errorCode'], 'domain');
    expect(entry.toReportJson()['schemaVersion'], 1);
  });

  test('fingerprint includes bin, kind, type and source', () {
    final entry = ErrorEntry.fromFailure(const Failure(bin: Bin.bug),
        errorType: 'StateError',
        source: 'A',
        stackTrace: '',
        timestamp: DateTime.now());
    final other = ErrorEntry.fromFailure(const Failure(bin: Bin.domain),
        errorType: 'StateError',
        source: 'A',
        stackTrace: '',
        timestamp: DateTime.now());
    expect(ErrorBoxEntry.generateFingerprint(entry),
        isNot(ErrorBoxEntry.generateFingerprint(other)));
  });
}
