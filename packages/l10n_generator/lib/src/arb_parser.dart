import 'package:l10n_key_resolver/l10n_key_resolver.dart';

/// Represents a parsed ARB entry with its metadata.
class ArbEntry {
  /// The ARB key (camelCase, e.g., 'errorAuthFailed')
  final String arbKey;

  /// The dot-notation key (e.g., 'error.auth.failed')
  final String dotKey;

  /// The default value/message
  final String value;

  /// Placeholder parameters, if any
  final List<ArbPlaceholder> placeholders;

  /// Description from ARB metadata
  final String? description;

  const ArbEntry({
    required this.arbKey,
    required this.dotKey,
    required this.value,
    this.placeholders = const [],
    this.description,
  });

  /// Whether this entry has parameters
  bool get hasParameters => placeholders.isNotEmpty;
}

/// How an argument is used in the message text.
enum ArbArgKind { simple, plural, select }

/// Represents a placeholder parameter in an ARB entry.
class ArbPlaceholder {
  final String name;

  /// The type declared in the `@key` metadata, if any.
  final String? type;
  final ArbArgKind kind;
  final String? description;

  const ArbPlaceholder({
    required this.name,
    this.type,
    this.kind = ArbArgKind.simple,
    this.description,
  });

  /// The Dart type `flutter gen-l10n` gives this argument.
  ///
  /// A declared type wins. Undeclared: a plural count is `num`, a select
  /// argument is `String`, anything else is `Object`.
  String get dartType {
    final declared = type;
    if (declared != null) {
      return switch (declared.toLowerCase()) {
        'int' || 'integer' => 'int',
        'double' => 'double',
        'num' || 'number' => 'num',
        'datetime' || 'date' => 'DateTime',
        'string' => 'String',
        _ => 'Object',
      };
    }
    return switch (kind) {
      ArbArgKind.plural => 'num',
      ArbArgKind.select => 'String',
      ArbArgKind.simple => 'Object',
    };
  }
}

/// Parses ARB JSON into structured entries.
class ArbParser {
  /// Parses ARB JSON map into a list of ArbEntry objects.
  ///
  /// Filters out:
  /// - Keys starting with '@' (metadata)
  /// - Keys starting with '@@' (file-level metadata like @@locale)
  List<ArbEntry> parse(Map<String, dynamic> arbData) {
    final entries = <ArbEntry>[];

    for (final key in arbData.keys) {
      // Skip metadata keys
      if (key.startsWith('@')) continue;

      final value = arbData[key];
      if (value is! String) continue;

      // Get metadata for this key (if exists)
      final metadataKey = '@$key';
      final metadata = arbData[metadataKey] as Map<String, dynamic>?;

      // The message is the source of truth for whether it takes arguments.
      // Metadata is optional in ARB files, and is used only to add details
      // (such as argument types) for arguments present in the message.
      final placeholders = _parsePlaceholders(key, value, metadata);

      // Convert camelCase ARB key to dot-notation
      final dotKey = KeyConverter.camelCaseToDot(key);

      entries.add(
        ArbEntry(
          arbKey: key,
          dotKey: dotKey,
          value: value,
          placeholders: placeholders,
          description: metadata?['description'] as String?,
        ),
      );
    }

    // Sort by dot key for consistent output
    entries.sort((a, b) => a.dotKey.compareTo(b.dotKey));

    return entries;
  }

  /// Finds the arguments of an ICU message, in order of first appearance.
  ///
  /// Only `{name}` and `{name, type, ...}` introduce an argument. The text
  /// inside plural/select branches is itself a message and is scanned for
  /// nested arguments, never mistaken for one.
  List<ArbPlaceholder> _parsePlaceholders(
    String arbKey,
    String value,
    Map<String, dynamic>? metadata,
  ) {
    final placeholdersData = metadata?['placeholders'] as Map?;
    final kinds = <String, ArbArgKind>{};
    try {
      _scan(value, _Cursor(), kinds, nested: false);
    } on FormatException catch (e) {
      throw FormatException('$arbKey: ${e.message}');
    }

    return [
      for (final e in kinds.entries)
        ArbPlaceholder(
          name: e.key,
          type: (placeholdersData?[e.key] as Map?)?['type'] as String?,
          kind: e.value,
          description:
              (placeholdersData?[e.key] as Map?)?['description'] as String?,
        ),
    ];
  }

  static final RegExp _identifier = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');

  /// Scans message text from the cursor. When [nested], stops after the
  /// closing `}` of the enclosing branch; otherwise reads to the end.
  void _scan(
    String s,
    _Cursor c,
    Map<String, ArbArgKind> out, {
    required bool nested,
  }) {
    while (c.i < s.length) {
      final ch = s[c.i];
      if (ch == "'") {
        final next = c.i + 1 < s.length ? s[c.i + 1] : '';
        if (next == "'") {
          c.i += 2;
        } else if (next == '{' || next == '}') {
          final close = s.indexOf("'", c.i + 1);
          c.i = close == -1 ? s.length : close + 1;
        } else {
          c.i++;
        }
      } else if (ch == '{') {
        c.i++;
        _scanArgument(s, c, out);
      } else if (ch == '}') {
        if (!nested) throw FormatException('unmatched "}"');
        c.i++;
        return;
      } else {
        c.i++;
      }
    }
    if (nested) throw const FormatException('missing "}"');
  }

  void _scanArgument(String s, _Cursor c, Map<String, ArbArgKind> out) {
    _skipSpace(s, c);
    final m = _identifier.matchAsPrefix(s, c.i);
    if (m == null) throw const FormatException('expected an argument name');
    final name = m.group(0)!;
    c.i = m.end;
    _skipSpace(s, c);
    if (c.i >= s.length) throw const FormatException('missing "}"');

    var kind = ArbArgKind.simple;
    if (s[c.i] == ',') {
      c.i++;
      _skipSpace(s, c);
      final t = _identifier.matchAsPrefix(s, c.i);
      final type = t?.group(0) ?? '';
      c.i = t?.end ?? c.i;
      _skipSpace(s, c);
      final isBranching =
          type == 'plural' || type == 'select' || type == 'selectordinal';
      if (isBranching && c.i < s.length && s[c.i] == ',') {
        kind = type == 'select' ? ArbArgKind.select : ArbArgKind.plural;
        c.i++;
        _record(out, name, kind);
        _scanBranches(s, c, out);
        return;
      }
      // Format argument, e.g. `{price, number, currency}`: skip to its `}`.
      while (c.i < s.length && s[c.i] != '}') {
        c.i++;
      }
    }
    if (c.i >= s.length) throw const FormatException('missing "}"');
    c.i++; // the closing "}"
    _record(out, name, kind);
  }

  void _scanBranches(String s, _Cursor c, Map<String, ArbArgKind> out) {
    while (true) {
      while (c.i < s.length && s[c.i] != '{' && s[c.i] != '}') {
        c.i++;
      }
      if (c.i >= s.length) throw const FormatException('missing "}"');
      if (s[c.i] == '}') {
        c.i++;
        return;
      }
      c.i++; // the branch's "{"
      _scan(s, c, out, nested: true);
    }
  }

  void _skipSpace(String s, _Cursor c) {
    while (c.i < s.length && s[c.i].trim().isEmpty) {
      c.i++;
    }
  }

  /// First appearance fixes the order; a plural/select use upgrades the kind.
  void _record(Map<String, ArbArgKind> out, String name, ArbArgKind kind) {
    final prev = out[name];
    if (prev == null || (prev == ArbArgKind.simple && kind != prev)) {
      out[name] = kind;
    }
  }
}

class _Cursor {
  int i = 0;
}
