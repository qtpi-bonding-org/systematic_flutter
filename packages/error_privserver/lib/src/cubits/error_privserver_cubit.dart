import 'dart:async';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../config/error_privserver_config.dart';
import '../inbox.dart';

mixin ErrorPrivserverMixin<S extends IUiFlowState> on TryOperationCubit<S> {
  static ErrorPrivserverConfig? _config;
  static ErrorInbox? _inbox;
  static void configure(ErrorPrivserverConfig config) {
    _config = config;
    _inbox = ErrorInbox(config.storage, config.retention, config.buildInfo);
  }

  static ErrorPrivserverConfig? get config => _config;
  static Future<void> record(Object error, StackTrace stack,
      {required String source}) async {
    final inbox = _inbox;
    if (inbox != null) {
      await inbox.record(error, stack, source: source);
    }
  }

  static void reset() {
    _config = null;
    _inbox?.reset();
    _inbox = null;
  }

  @override
  void onOperationError(Object error, StackTrace stackTrace) {
    super.onOperationError(error, stackTrace);
    final inbox = _inbox;
    if (inbox != null)
      unawaited(
          inbox.record(error, stackTrace, source: runtimeType.toString()));
  }
}
