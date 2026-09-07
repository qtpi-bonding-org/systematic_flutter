import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _FlutterUiLintsPlugin();

class _FlutterUiLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [];
}
