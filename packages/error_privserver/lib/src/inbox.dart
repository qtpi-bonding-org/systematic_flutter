import 'dart:async';
import 'package:systematic_failure/systematic_failure.dart';
import 'build_info.dart';
import 'models/error_entry.dart';
import 'retention_policy.dart';
import 'storage/error_box_storage.dart';

/// The one capture path: classify, store, prune, serialized so concurrent
/// failures lose no rows. Stores type names only, never error text.
class ErrorInbox {
  ErrorInbox(this.storage, this.retention, this.buildInfo);
  final ErrorBoxStorage storage;
  final RetentionPolicy retention;
  final BuildInfo buildInfo;
  Future<void> _tail = Future<void>.value();

  Future<void> record(Object error, StackTrace stack,
      {required String source}) {
    final job = _tail.then((_) async {
      try {
        final failure = classify(error);
        final entry = ErrorEntry.fromFailure(failure,
            errorType: error.runtimeType.toString(),
            source: source,
            stackTrace: stack.toString(),
            timestamp: DateTime.now(),
            buildInfo: buildInfo);
        await storage.saveError(entry);
        final all = await storage.getAll();
        final ids = idsToPrune(all, retention, DateTime.now());
        if (ids.isNotEmpty) await storage.deleteErrors(ids);
      } catch (_) {}
    });
    _tail = job.catchError((_) {});
    return job;
  }

  void reset() {
    _tail = Future<void>.value();
  }
}
