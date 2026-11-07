import 'src/models/error_entry.dart';
import 'src/storage/error_box_storage.dart';

/// In-memory storage with the same dedup rules as the shared-prefs one.
class InMemoryErrorBoxStorage implements ErrorBoxStorage {
  final List<ErrorBoxEntry> entries = [];
  @override
  Future<void> saveError(ErrorEntry error) async =>
      saveDeduplicated(entries, error);
  @override
  Future<List<ErrorBoxEntry>> getAll() async => List.of(entries);
  @override
  Future<void> deleteErrors(List<String> ids) async =>
      entries.removeWhere((e) => ids.contains(e.id));
  @override
  Future<List<ErrorBoxEntry>> getUnsentErrors() async =>
      entries.where((e) => !e.wasSent).toList();
  @override
  Future<ErrorBoxEntry?> getErrorById(String id) async {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<void> markAsSent(String id) async {
    final i = entries.indexWhere((e) => e.id == id);
    if (i >= 0)
      entries[i] = entries[i].copyWith(wasSent: true, sentAt: DateTime.now());
  }

  @override
  Future<void> deleteError(String id) => deleteErrors([id]);
  @override
  Future<int> getUnsentCount() async => (await getUnsentErrors()).length;
}
