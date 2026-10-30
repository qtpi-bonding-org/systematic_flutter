import 'dart:io';

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Options for the rules, read from `lint_config.yaml` at the root of the
/// analyzed package, so one plugin serves every app.
///
/// ```yaml
/// exclude: [test/**, "**/*.g.dart"]   # replaces the default global excludes
/// no_hardcoded_colors:
///   banned_types: [Colors]
///   include: [lib/**]                 # only these paths; ignores the global excludes
///   exclude: [lib/dev/**]             # added to the global excludes
/// ```
class LintConfig {
  const LintConfig._(this._rules, this._globalExclude);

  /// Paths no rule looks at unless it opts in with `include`.
  static const defaultExclude = [
    'test/**',
    'integration_test/**',
    '**/*.g.dart',
    '**/*.freezed.dart',
    '**/*.config.dart',
    '**/*.stories.dart',
  ];

  static const empty = LintConfig._({}, defaultExclude);

  factory LintConfig.parse(String source) {
    final doc = loadYaml(source);
    if (doc is! YamlMap) return empty;
    final rules = <String, Map<String, Object?>>{};
    var globalExclude = defaultExclude;
    for (final entry in doc.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (key == 'exclude') {
        globalExclude = _strings(value);
      } else if (value is YamlMap) {
        rules[key] = {for (final e in value.entries) e.key.toString(): e.value};
      }
    }
    return LintConfig._(rules, globalExclude);
  }

  final Map<String, Map<String, Object?>> _rules;
  final List<String> _globalExclude;

  List<String> list(String rule, String key, List<String> fallback) {
    final value = _rules[rule]?[key];
    return value is YamlList ? _strings(value) : fallback;
  }

  String string(String rule, String key, String fallback) {
    final value = _rules[rule]?[key];
    return value is String ? value : fallback;
  }

  /// Whether [rule] looks at [relativePath] (relative to the package root,
  /// `/`-separated).
  bool appliesTo(String rule, String relativePath) {
    final include = list(rule, 'include', const []);
    final exclude = list(rule, 'exclude', const []);
    if (_matches(exclude, relativePath)) return false;
    if (include.isNotEmpty) return _matches(include, relativePath);
    return !_matches(_globalExclude, relativePath);
  }

  static bool _matches(List<String> patterns, String path) =>
      patterns.any((pattern) => Glob(pattern).matches(path));

  static List<String> _strings(Object? value) =>
      value is YamlList ? [for (final v in value) v.toString()] : const [];

  static final _cache = <String, ({DateTime modified, LintConfig config})>{};

  /// The config of the package [context] is analyzing; [empty] when it has none.
  static LintConfig forContext(RuleContext context) {
    final root = context.package?.root.path;
    if (root == null) return empty;
    final file = File(p.join(root, 'lint_config.yaml'));
    if (!file.existsSync()) return empty;
    final modified = file.lastModifiedSync();
    final cached = _cache[root];
    if (cached != null && cached.modified == modified) return cached.config;
    final config = LintConfig.parse(file.readAsStringSync());
    _cache[root] = (modified: modified, config: config);
    return config;
  }

  /// Whether [rule] should look at the file [context] is analyzing.
  static bool applies(RuleContext context, String rule) {
    final unit = context.currentUnit ?? context.definingUnit;
    final root = context.package?.root.path;
    if (root == null) return true;
    final relative = p
        .relative(unit.file.path, from: root)
        .replaceAll(r'\', '/');
    return forContext(context).appliesTo(rule, relative);
  }
}
