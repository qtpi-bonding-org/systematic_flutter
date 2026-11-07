import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:systematic_failure/systematic_failure.dart';
import 'package:flutter_error_privserver/testing.dart';

void main() {
  test('in-memory testing storage deduplicates unsent entries', () async {
    final storage = InMemoryErrorBoxStorage();
    final entry = ErrorEntry.fromFailure(const Failure(bin: Bin.bug),
        errorType: 'StateError',
        source: 'test',
        stackTrace: '',
        timestamp: DateTime.now());
    await storage.saveError(entry);
    await storage.saveError(entry);
    expect(storage.entries, hasLength(1));
    expect(storage.entries.single.occurrenceCount, 2);
    await storage.deleteErrors([storage.entries.single.id]);
    expect(storage.entries, isEmpty);
  });
}
