import 'dart:io';

import 'package:yaml/yaml.dart';

/// One configurable value: which rule/key it comes from in `lint_config.yaml`,
/// what top-level const name it's rendered as, and its default.
class _ConfigField {
  const _ConfigField({
    required this.rule,
    required this.key,
    required this.constName,
    required this.isList,
    required this.defaultValue,
  });

  final String rule;
  final String key;
  final String constName;
  final bool isList;
  final Object defaultValue;
}

const _fields = [
  _ConfigField(
    rule: 'no_hardcoded_colors',
    key: 'banned_types',
    constName: 'noHardcodedColorsBannedTypes',
    isList: true,
    defaultValue: ['Colors', 'AppPalette'],
  ),
  _ConfigField(
    rule: 'no_hardcoded_font_family',
    key: 'allowed_types',
    constName: 'noHardcodedFontFamilyAllowedTypes',
    isList: true,
    defaultValue: ['AppFonts'],
  ),
  _ConfigField(
    rule: 'no_raw_sizedbox_spacing',
    key: 'allowed_enclosing_classes',
    constName: 'noRawSizedboxSpacingAllowedEnclosingClasses',
    isList: true,
    defaultValue: ['VSpace', 'HSpace'],
  ),
  _ConfigField(
    rule: 'no_inline_widget_composition_in_pages',
    key: 'page_suffix',
    constName: 'noInlineWidgetCompositionInPagesPageSuffix',
    isList: false,
    defaultValue: 'Screen',
  ),
  _ConfigField(
    rule: 'no_inline_widget_composition_in_pages',
    key: 'widget_dir_names',
    constName: 'noInlineWidgetCompositionInPagesWidgetDirNames',
    isList: true,
    defaultValue: ['widgets', 'adapters'],
  ),
  _ConfigField(
    rule: 'no_inline_widget_composition_in_pages',
    key: 'banned_widget_names',
    constName: 'noInlineWidgetCompositionInPagesBannedWidgetNames',
    isList: true,
    defaultValue: [
      'Padding',
      'Column',
      'Row',
      'Container',
      'SizedBox',
      'Text',
      'Icon',
      'Stack',
      'ListView',
      'GridView',
      'Align',
      'Center',
      'Expanded',
      'Flexible',
      'Card',
      'Scaffold',
      'AppBar',
    ],
  ),
  _ConfigField(
    rule: 'no_hardcoded_strings',
    key: 'allowed_types',
    constName: 'noHardcodedStringsAllowedTypes',
    isList: true,
    defaultValue: ['MessageKey'],
  ),
];

/// Renders [value] (a String or List<String>) as a Dart literal.
String _renderLiteral(Object value) {
  if (value is String) return "'${value.replaceAll("'", r"\'")}'";
  final items = (value as List).cast<Object>().map(_renderLiteral).join(', ');
  return '[$items]';
}

String _renderFile(YamlMap? config) {
  final buffer = StringBuffer()
    ..writeln(
      '// GENERATED -- do not edit by hand. Run `dart run '
      'bin/generate.dart` to regenerate from lint_config.yaml.',
    )
    ..writeln();

  for (var i = 0; i < _fields.length; i++) {
    final field = _fields[i];
    final ruleConfig = config?[field.rule];
    Object value = field.defaultValue;
    if (ruleConfig != null && ruleConfig[field.key] != null) {
      final raw = ruleConfig[field.key];
      value = field.isList
          ? (raw as YamlList).map((e) => e.toString()).toList()
          : raw.toString();
    }
    buffer.writeln('const ${field.constName} = ${_renderLiteral(value)};');
    if (i != _fields.length - 1) buffer.writeln();
  }

  return buffer.toString();
}

void main(List<String> args) {
  final configPath = args.isNotEmpty ? args[0] : 'lint_config.yaml';
  final outPath = args.length > 1 ? args[1] : 'lib/generated_config.dart';

  final configFile = File(configPath);
  final config = configFile.existsSync()
      ? loadYaml(configFile.readAsStringSync()) as YamlMap?
      : null;

  File(outPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(_renderFile(config));

  stdout.writeln(
    'Wrote $outPath from ${configFile.existsSync() ? configPath : '(no config file -- used defaults)'}.',
  );
}
