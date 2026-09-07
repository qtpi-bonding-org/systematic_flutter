import 'package:custom_lint_builder/custom_lint_builder.dart';

List<String> stringListOption(
  CustomLintConfigs configs,
  String ruleName,
  String key,
  List<String> defaults,
) {
  final raw = configs.rules[ruleName]?.json[key];
  if (raw is List) return raw.map((e) => e.toString()).toList();
  return defaults;
}

String stringOption(
  CustomLintConfigs configs,
  String ruleName,
  String key,
  String defaultValue,
) {
  final raw = configs.rules[ruleName]?.json[key];
  if (raw is String) return raw;
  return defaultValue;
}
