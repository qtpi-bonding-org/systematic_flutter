import 'arb_parser.dart';

/// Generates `L10nKeys` and `L10nKeyResolver` from parsed ARB entries.
///
/// The output has no timestamp: it is committed, so identical input must
/// give identical bytes.
class ResolverGenerator {
  final String localizationsClass;
  final String localizationsImport;
  final bool generateDotKeys;

  ResolverGenerator({
    required this.localizationsClass,
    required this.localizationsImport,
    this.generateDotKeys = true,
  });

  String _keyOf(ArbEntry e) => generateDotKeys ? e.dotKey : e.arbKey;

  String generate(List<ArbEntry> entries) {
    final b = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
      ..writeln('// Generator: l10n_generator')
      ..writeln()
      ..writeln("import 'package:l10n_key_resolver/runtime.dart';")
      ..writeln("import '$localizationsImport';")
      ..writeln();

    _resolver(b, entries);
    b.writeln();
    _keys(b, entries);
    return b.toString();
  }

  void _resolver(StringBuffer b, List<ArbEntry> entries) {
    b
      ..writeln('/// Resolves [Label]s to text for the locale of the wrapped')
      ..writeln('/// [$localizationsClass].')
      ..writeln('///')
      ..writeln(
          '/// An unknown key calls [onUnknownKey]; debug builds and tests')
      ..writeln('/// then throw, release builds show the key text.')
      ..writeln('class L10nKeyResolver implements LabelResolver {')
      ..writeln('  final $localizationsClass _l10n;')
      ..writeln('  final UnknownKeyHandler? onUnknownKey;')
      ..writeln()
      ..writeln('  const L10nKeyResolver(this._l10n, {this.onUnknownKey});')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  String resolve(Label label) => switch (label) {')
      ..writeln('        DataText(:final value) => value,')
      ..writeln(
          '        L10nKey(:final key, :final args) => _byKey(key, args),')
      ..writeln('      };')
      ..writeln()
      ..writeln('  String _byKey(String key, Map<String, Object> args) {')
      ..writeln('    return switch (key) {');
    for (final e in entries) {
      final call = e.hasParameters
          ? '_l10n.${e.arbKey}(${e.placeholders.map((p) => "args['${p.name}'] as ${p.dartType}").join(', ')})'
          : '_l10n.${e.arbKey}';
      b.writeln("      '${_keyOf(e)}' => $call,");
    }
    b
      ..writeln('      _ => _unknown(key),')
      ..writeln('    };')
      ..writeln('  }')
      ..writeln()
      ..writeln('  String _unknown(String key) {')
      ..writeln('    onUnknownKey?.call(key);')
      ..writeln('    var isDebug = false;')
      ..writeln('    assert(isDebug = true);')
      ..writeln("    if (isDebug) throw StateError('Unknown l10n key: \$key');")
      ..writeln('    return key;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// Every key this resolver knows.')
      ..writeln('  static const knownKeys = <String>{');
    for (final e in entries) {
      b.writeln("    '${_keyOf(e)}',");
    }
    b
      ..writeln('  };')
      ..writeln()
      ..writeln('  static bool hasKey(String key) => knownKeys.contains(key);');
    if (generateDotKeys) {
      b
        ..writeln()
        ..writeln('  /// ARB camelCase key to dot-notation key.')
        ..writeln('  static const arbToDotKey = <String, String>{');
      for (final e in entries) {
        b.writeln("    '${e.arbKey}': '${e.dotKey}',");
      }
      b
        ..writeln('  };')
        ..writeln()
        ..writeln('  /// Dot-notation key to ARB camelCase key.')
        ..writeln('  static const dotToArbKey = <String, String>{');
      for (final e in entries) {
        b.writeln("    '${e.dotKey}': '${e.arbKey}',");
      }
      b.writeln('  };');
    }
    b.writeln('}');
  }

  void _keys(StringBuffer b, List<ArbEntry> entries) {
    b
      ..writeln('/// The only source of [L10nKey]s.')
      ..writeln('///')
      ..writeln(
          '/// Plain keys are const; parameterized keys are methods, so they')
      ..writeln('/// cannot be used in a const context.')
      ..writeln('abstract final class L10nKeys {');
    for (final e in entries) {
      final key = _keyOf(e);
      if (e.hasParameters) {
        final params =
            e.placeholders.map((p) => 'required ${p.dartType} ${p.name}');
        final args = e.placeholders.map((p) => "'${p.name}': ${p.name}");
        b.writeln(
          '  static L10nKey ${e.arbKey}({${params.join(', ')}}) => '
          "L10nKey.generated('$key', {${args.join(', ')}});",
        );
      } else {
        b.writeln("  static const ${e.arbKey} = L10nKey.generated('$key');");
      }
    }
    b.writeln('}');
  }
}
