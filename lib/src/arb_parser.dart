import 'key_converter.dart';

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

/// Represents a placeholder parameter in an ARB entry.
class ArbPlaceholder {
  final String name;
  final String type;
  final String? description;

  const ArbPlaceholder({
    required this.name,
    required this.type,
    this.description,
  });

  /// Returns the Dart type for this placeholder
  String get dartType {
    return switch (type.toLowerCase()) {
      'int' || 'integer' => 'int',
      'double' || 'num' || 'number' => 'num',
      'datetime' || 'date' => 'DateTime',
      _ => 'String',
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
      final placeholders = _parsePlaceholders(value, metadata);

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

  /// Parses placeholders from a message and supplements them with metadata.
  ///
  /// This recognizes the argument identifier at the start of both simple ICU
  /// arguments (`{name}`) and complex ICU arguments (`{count, plural, ...}`).
  /// Repeated arguments are de-duplicated while preserving message order.
  List<ArbPlaceholder> _parsePlaceholders(
    String value,
    Map<String, dynamic>? metadata,
  ) {
    final placeholdersData = metadata?['placeholders'] as Map?;
    final placeholders = <ArbPlaceholder>[];
    final names = <String>{};

    for (final match in _placeholderPattern.allMatches(value)) {
      final name = match.group(1)!;
      if (!names.add(name)) continue;

      final data = placeholdersData?[name] as Map?;
      placeholders.add(
        ArbPlaceholder(
          name: name,
          type: data?['type'] as String? ?? 'String',
          description: data?['description'] as String?,
        ),
      );
    }

    return placeholders;
  }

  static final RegExp _placeholderPattern = RegExp(
    r'\{([A-Za-z_][A-Za-z0-9_]*)\s*(?:,|\})',
  );
}
