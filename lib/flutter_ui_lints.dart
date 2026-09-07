import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rule_config.dart';
import 'src/rules/no_hardcoded_colors.dart';

PluginBase createPlugin() => _FlutterUiLintsPlugin();

class _FlutterUiLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        NoHardcodedColors(
          bannedTypes: stringListOption(
            configs,
            'no_hardcoded_colors',
            'banned_types',
            const ['Colors', 'AppPalette'],
          ),
        ),
      ];
}
