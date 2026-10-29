/// Typed localized labels.
///
/// A plain `String` can be English in a Spanish UI and nothing stops it
/// reaching a screen reader. APIs that need a localized label take a [Label]
/// instead: either an [L10nKey] (only the generated `L10nKeys` produce one) or
/// a [DataText] (runtime data, shown as is, greppable).
///
/// `sealed` needs every subtype in this library, so all of them live here.
library;

/// A user-visible text that is either a localized key or explicit data.
sealed class Label {
  const Label();
}

/// A reference to an ARB message, with its arguments.
///
/// Obtain one from the generated `L10nKeys`. The [generated] constructor is
/// public only because Dart has no friend access; `assertNoHandwrittenKeys`
/// fails a test when it is called outside a `*.g.dart` file.
final class L10nKey extends Label {
  /// The dot-notation key, e.g. `error.auth.failed`.
  final String key;

  /// Arguments for a parameterized message. Empty for plain keys.
  final Map<String, Object> args;

  const L10nKey.generated(this.key, [this.args = const {}]);

  @override
  bool operator ==(Object other) =>
      other is L10nKey && other.key == key && _mapEquals(other.args, args);

  @override
  int get hashCode => Object.hash(
        key,
        Object.hashAllUnordered(
          args.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );

  @override
  String toString() => args.isEmpty ? 'L10nKey($key)' : 'L10nKey($key, $args)';
}

/// Text that comes from data (a note title, a tool name), shown as is.
final class DataText extends Label {
  final String value;

  const DataText(this.value);

  @override
  bool operator ==(Object other) => other is DataText && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DataText($value)';
}

/// Turns a [Label] into text for the current locale.
abstract interface class LabelResolver {
  String resolve(Label label);
}

/// Called when a key has no message (debug builds throw instead).
typedef UnknownKeyHandler = void Function(String key);

bool _mapEquals(Map<String, Object> a, Map<String, Object> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key) || b[e.key] != e.value) return false;
  }
  return true;
}
