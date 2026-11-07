import '../build_info.dart';
import '../models/error_entry.dart';
import '../retention_policy.dart';
import '../storage/error_box_storage.dart';

/// Configuration for flutter_error_privserver.
///
/// The library captures failures and stores them locally; showing them is the
/// app's job. Classification comes from `systematic_failure` (configure its
/// policy first).
class ErrorPrivserverConfig {
  const ErrorPrivserverConfig({
    required this.storage,
    required this.reporter,
    this.retention = const RetentionPolicy(),
    this.buildInfo = const BuildInfo.fromEnvironment(),
  });

  /// Storage implementation for error box entries.
  final ErrorBoxStorage storage;

  /// Function to send error entries to the server.
  final Future<bool> Function(ErrorEntry) reporter;

  /// What the inbox keeps (row cap, age per bin, sent rows).
  final RetentionPolicy retention;

  /// App version and commit stamped on every row.
  final BuildInfo buildInfo;
}
