import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rule_config.dart';
import 'src/rules/no_hardcoded_colors.dart';
import 'src/rules/no_hardcoded_font_family.dart';
import 'src/rules/no_hardcoded_font_size.dart';
import 'src/rules/no_raw_sizedbox_spacing.dart';

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
        const NoHardcodedFontSize(),
        NoHardcodedFontFamily(
          allowedTypes: stringListOption(
            configs,
            'no_hardcoded_font_family',
            'allowed_types',
            const ['AppFonts'],
          ),
        ),
        NoRawSizedBoxSpacing(
          allowedEnclosingClasses: stringListOption(
            configs,
            'no_raw_sizedbox_spacing',
            'allowed_enclosing_classes',
            const ['VSpace', 'HSpace'],
          ),
        ),
      ];
}
