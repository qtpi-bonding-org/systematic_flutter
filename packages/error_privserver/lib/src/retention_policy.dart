import 'package:systematic_failure/systematic_failure.dart';
import 'models/error_entry.dart';

/// What the inbox keeps: a row cap, a maximum age per bin (measured from
/// `lastOccurred`), and whether sent rows are pruned.
class RetentionPolicy {
  const RetentionPolicy({
    this.maxEntries = 200,
    this.maxAge = const {
      Bin.bug: Duration(days: 90),
      Bin.environment: Duration(days: 30),
      Bin.domain: Duration(days: 14),
    },
    this.pruneSent = true,
  });
  final int maxEntries;
  final Map<Bin, Duration?> maxAge;
  final bool pruneSent;
}

/// Ids to delete: sent rows (if pruneSent), rows past their bin's age, then
/// over the cap: sent first, then domain, then oldest `lastOccurred`.
List<String> idsToPrune(
    List<ErrorBoxEntry> all, RetentionPolicy p, DateTime now) {
  final ids = <String>{};
  if (p.pruneSent) ids.addAll(all.where((e) => e.wasSent).map((e) => e.id));
  for (final e in all) {
    final age = p.maxAge[e.errorData.bin];
    if (age != null && now.difference(e.lastOccurred) > age) ids.add(e.id);
  }
  final remaining = all.where((e) => !ids.contains(e.id)).toList();
  if (remaining.length > p.maxEntries) {
    final candidates = [...remaining]..sort((a, b) {
        final sent = (b.wasSent ? 1 : 0).compareTo(a.wasSent ? 1 : 0);
        if (sent != 0) return sent;
        final domain = (b.errorData.bin == Bin.domain ? 1 : 0)
            .compareTo(a.errorData.bin == Bin.domain ? 1 : 0);
        if (domain != 0) return domain;
        return a.lastOccurred.compareTo(b.lastOccurred);
      });
    ids.addAll(
        candidates.take(remaining.length - p.maxEntries).map((e) => e.id));
  }
  return ids.toList();
}
