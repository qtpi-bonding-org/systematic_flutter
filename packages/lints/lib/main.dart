import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/avoid_bloc_imports_in_widgets_dir.dart';
import 'src/rules/avoid_getit_in_adapters_dir.dart';
import 'src/rules/cubit_field_selector_must_be_equatable.dart';
import 'src/rules/no_duplicate_cubitfield_keys.dart';
import 'src/rules/no_hardcoded_colors.dart';
import 'src/rules/no_hardcoded_font_family.dart';
import 'src/rules/no_hardcoded_font_size.dart';
import 'src/rules/no_hardcoded_padding.dart';
import 'src/rules/no_hardcoded_strings.dart';
import 'src/rules/no_inline_widget_composition_in_pages.dart';
import 'src/rules/no_raw_sizedbox_spacing.dart';
import 'src/rules/require_cubitfield_over_raw_bloc_apis.dart';
import 'src/rules/require_static_selector.dart';

final plugin = SystematicLintsPlugin();

class SystematicLintsPlugin extends Plugin {
  @override
  String get name => 'systematic_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(NoHardcodedColors())
      ..registerLintRule(NoHardcodedFontSize())
      ..registerLintRule(NoHardcodedFontFamily())
      ..registerLintRule(NoRawSizedboxSpacing())
      ..registerLintRule(NoHardcodedPadding())
      ..registerLintRule(NoInlineWidgetCompositionInPages())
      ..registerLintRule(NoHardcodedStrings())
      ..registerLintRule(AvoidBlocImportsInWidgetsDir())
      ..registerLintRule(AvoidGetItInAdaptersDir())
      ..registerLintRule(RequireCubitFieldOverRawBlocApis())
      ..registerLintRule(RequireStaticSelector())
      ..registerLintRule(CubitFieldSelectorMustBeEquatable())
      ..registerLintRule(NoDuplicateCubitFieldKeys());
  }
}
