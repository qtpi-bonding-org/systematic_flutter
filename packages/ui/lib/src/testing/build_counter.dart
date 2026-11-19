import 'package:flutter/widgets.dart';

/// Counts how many times each [BuildCounter] id has run its `build`.
///
/// Test helper: wrap a subtree in it to assert how often that subtree rebuilds.
/// Counts are process-wide, so call [reset] in `setUp`.
class BuildCounter extends StatelessWidget {
  const BuildCounter({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  static final Map<String, int> _counts = <String, int>{};

  @override
  Widget build(BuildContext context) {
    _counts[id] = (_counts[id] ?? 0) + 1;
    return child;
  }

  /// Number of builds recorded for [id]; 0 when the id has never built.
  static int count(String id) => _counts[id] ?? 0;

  /// Clears all recorded counts.
  static void reset() => _counts.clear();
}
