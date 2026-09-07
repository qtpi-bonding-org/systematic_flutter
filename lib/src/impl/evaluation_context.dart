/// Records which parts were read during one policy evaluation.
class EvaluationContext {
  static EvaluationContext? _current;

  final Set<Object> _reads = <Object>{};

  /// The parts read during this evaluation.
  Set<Object> get reads => Set<Object>.unmodifiable(_reads);

  /// The evaluation currently in progress, or null outside one.
  static EvaluationContext? get current => _current;

  /// Records that [part] was read.
  void recordRead(Object part) => _reads.add(part);

  /// Runs [body] with [context] installed as [current].
  static R track<R>(EvaluationContext context, R Function() body) {
    final previous = _current;
    _current = context;
    try {
      return body();
    } finally {
      _current = previous;
    }
  }
}
