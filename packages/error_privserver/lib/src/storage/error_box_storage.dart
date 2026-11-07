import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/error_entry.dart';

abstract class ErrorBoxStorage {
  Future<void> saveError(ErrorEntry error);

  /// Every stored row, sent or not (retention needs the whole inbox).
  Future<List<ErrorBoxEntry>> getAll();

  /// Removes the rows with these ids; unknown ids are ignored.
  Future<void> deleteErrors(List<String> ids);

  Future<List<ErrorBoxEntry>> getUnsentErrors();
  Future<ErrorBoxEntry?> getErrorById(String id);
  Future<void> markAsSent(String id);
  Future<void> deleteError(String id);
  Future<int> getUnsentCount();
}

void saveDeduplicated(List<ErrorBoxEntry> entries, ErrorEntry error) {
  final fingerprint = ErrorBoxEntry.generateFingerprint(error);
  final index =
      entries.indexWhere((e) => e.fingerprint == fingerprint && !e.wasSent);
  if (index >= 0) {
    entries[index] = entries[index].incrementCount();
  } else {
    final now = DateTime.now();
    entries.add(ErrorBoxEntry(
        id: const Uuid().v4(),
        fingerprint: fingerprint,
        errorData: error,
        occurrenceCount: 1,
        firstOccurred: now,
        lastOccurred: now));
  }
}

class SharedPrefsErrorBoxStorage implements ErrorBoxStorage {
  static const _key = 'flutter_error_privserver_entries';
  Future<List<ErrorBoxEntry>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = jsonDecode(prefs.getString(_key) ?? '[]') as List;
      return list
          .map((e) => ErrorBoxEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<ErrorBoxEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  @override
  Future<void> saveError(ErrorEntry error) async {
    final e = await _load();
    saveDeduplicated(e, error);
    await _save(e);
  }

  @override
  Future<List<ErrorBoxEntry>> getAll() => _load();
  @override
  Future<void> deleteErrors(List<String> ids) async {
    final e = await _load();
    e.removeWhere((x) => ids.contains(x.id));
    await _save(e);
  }

  @override
  Future<List<ErrorBoxEntry>> getUnsentErrors() async =>
      (await _load()).where((e) => !e.wasSent).toList();
  @override
  Future<ErrorBoxEntry?> getErrorById(String id) async {
    for (final e in await _load()) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<void> markAsSent(String id) async {
    final e = await _load();
    final i = e.indexWhere((x) => x.id == id);
    if (i >= 0) {
      e[i] = e[i].copyWith(wasSent: true, sentAt: DateTime.now());
      await _save(e);
    }
  }

  @override
  Future<void> deleteError(String id) => deleteErrors([id]);
  @override
  Future<int> getUnsentCount() async => (await getUnsentErrors()).length;
}
