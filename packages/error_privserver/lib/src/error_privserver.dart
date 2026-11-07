import 'config/error_privserver_config.dart';
import 'cubits/error_privserver_cubit.dart';
import 'models/error_entry.dart';

class ErrorPrivserver {
  static void configure(ErrorPrivserverConfig config) =>
      ErrorPrivserverMixin.configure(config);
  static void reset() => ErrorPrivserverMixin.reset();
  static bool get isConfigured => ErrorPrivserverMixin.config != null;
  static Future<int> getUnsentCount() async {
    final c = ErrorPrivserverMixin.config;
    return c == null ? 0 : await c.storage.getUnsentCount();
  }

  static Future<List<ErrorBoxEntry>> getUnsentErrors() async {
    final c = ErrorPrivserverMixin.config;
    return c == null ? <ErrorBoxEntry>[] : await c.storage.getUnsentErrors();
  }

  static Future<bool> sendError(String id) async {
    final c = ErrorPrivserverMixin.config;
    if (c == null) return false;
    final e = await c.storage.getErrorById(id);
    return e != null && await c.reporter(e.errorData);
  }

  static Future<void> captureError(Object error, StackTrace stack,
      {required String source}) async {
    final c = ErrorPrivserverMixin.config;
    if (c == null) return;
    await ErrorPrivserverMixin.record(error, stack, source: source);
  }

  static Future<List<String>> sendAllErrors() async {
    final sent = <String>[];
    for (final e in await getUnsentErrors()) {
      if (await sendError(e.id)) {
        sent.add(e.id);
      } else {
        break;
      }
    }
    return sent;
  }
}
