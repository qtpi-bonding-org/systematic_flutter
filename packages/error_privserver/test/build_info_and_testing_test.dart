import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:flutter_error_privserver/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_failure/systematic_failure.dart';

ErrorEntry _entry(String source) => ErrorEntry(
      bin: Bin.environment,
      errorType: 'SocketException',
      source: source,
      stackTrace: '',
      timestamp: DateTime.utc(2026),
    );

void main() {
  test('BuildInfo.fromEnvironment is null without dart-defines', () {
    const info = BuildInfo.fromEnvironment();
    expect(info.appVersion, isNull);
    expect(info.commit, isNull);
  });

  test('in-memory storage dedups unsent rows and supports deleteErrors',
      () async {
    final s = InMemoryErrorBoxStorage();
    await s.saveError(_entry('A'));
    await s.saveError(_entry('A'));
    await s.saveError(_entry('B'));
    expect((await s.getAll()).length, 2);
    final first = (await s.getAll()).first;
    expect(first.occurrenceCount, 2);
    await s.markAsSent(first.id);
    expect(await s.getUnsentCount(), 1);
    await s.saveError(_entry('A')); // a sent row is not deduped against
    expect((await s.getAll()).length, 3);
    await s.deleteErrors([first.id, 'unknown']);
    expect((await s.getAll()).length, 2);
  });

  test('ErrorPrivserver.reset clears the configuration', () {
    ErrorPrivserver.configure(
      ErrorPrivserverConfig(
        storage: InMemoryErrorBoxStorage(),
        reporter: (_) async => true,
      ),
    );
    expect(ErrorPrivserver.isConfigured, isTrue);
    ErrorPrivserver.reset();
    expect(ErrorPrivserver.isConfigured, isFalse);
  });
}
