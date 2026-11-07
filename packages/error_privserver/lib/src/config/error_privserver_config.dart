import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../build_info.dart';
import '../models/error_entry.dart';
import '../retention_policy.dart';
import '../storage/error_box_storage.dart';

class ErrorPrivserverConfig {
  const ErrorPrivserverConfig({
    required this.storage,
    required this.reporter,
    this.retention = const RetentionPolicy(),
    this.buildInfo = const BuildInfo.fromEnvironment(),
    @Deprecated('Ignored; classification is provided by systematic_failure.')
    this.errorCodeMapper,
    @Deprecated('Ignored; classification is provided by systematic_failure.')
    this.exceptionMapper,
  });
  final ErrorBoxStorage storage;
  final Future<bool> Function(ErrorEntry) reporter;
  final RetentionPolicy retention;
  final BuildInfo buildInfo;
  @Deprecated('Ignored')
  final String Function(Object error)? errorCodeMapper;
  @Deprecated('Ignored')
  final MessageKey? Function(Object error)? exceptionMapper;
}
