import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/rules/actions_avoid_bloc_names.dart';
import 'src/rules/actions_return_void.dart';
import 'src/rules/adapter_naming.dart';
import 'src/rules/avoid_bloc_imports_in_widgets_dir.dart';
import 'src/rules/backend_access_only_in_adapters.dart';
import 'src/rules/avoid_getit_in_adapters_dir.dart';
import 'src/rules/cubit_field_selector_must_be_equatable.dart';
import 'src/rules/no_build_context_fields.dart';
import 'src/rules/no_duplicate_cubitfield_keys.dart';
import 'src/rules/no_banned_constructors.dart';
import 'src/rules/no_hardcoded_colors.dart';
import 'src/rules/no_hardcoded_font_family.dart';
import 'src/rules/no_hardcoded_font_size.dart';
import 'src/rules/no_hardcoded_padding.dart';
import 'src/rules/no_hardcoded_strings.dart';
import 'src/rules/no_inline_widget_composition_in_pages.dart';
import 'src/rules/no_raw_app_sizes.dart';
import 'src/rules/no_raw_sizedbox_spacing.dart';
import 'src/rules/require_cubitfield_over_raw_bloc_apis.dart';
import 'src/rules/require_static_selector.dart';
import 'src/rules/exceptions_extend_failure_base.dart';
import 'src/rules/throw_only_failure_types.dart';
import 'src/rules/no_bare_catch_conversion.dart';
import 'src/rules/no_error_to_text.dart';
import 'src/rules/no_string_error_in_state.dart';

final plugin = SystematicLintsPlugin();

class SystematicLintsPlugin extends Plugin {
  @override
  String get name => 'systematic_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(NoHardcodedColors())
      ..registerWarningRule(NoHardcodedFontSize())
      ..registerWarningRule(NoHardcodedFontFamily())
      ..registerWarningRule(NoRawSizedboxSpacing())
      ..registerWarningRule(NoRawAppSizes())
      ..registerWarningRule(NoBannedConstructors())
      ..registerWarningRule(NoHardcodedPadding())
      ..registerWarningRule(NoInlineWidgetCompositionInPages())
      ..registerWarningRule(NoHardcodedStrings())
      ..registerWarningRule(AvoidBlocImportsInWidgetsDir())
      ..registerWarningRule(AvoidGetItInAdaptersDir())
      ..registerWarningRule(RequireCubitFieldOverRawBlocApis())
      ..registerWarningRule(RequireStaticSelector())
      ..registerWarningRule(CubitFieldSelectorMustBeEquatable())
      ..registerWarningRule(NoDuplicateCubitFieldKeys())
      ..registerWarningRule(BackendAccessOnlyInAdapters())
      ..registerWarningRule(AdapterNaming())
      ..registerWarningRule(ActionsAvoidBlocNames())
      ..registerWarningRule(ActionsReturnVoid())
      ..registerWarningRule(NoBuildContextFields());
    registry
      ..registerWarningRule(ExceptionsExtendFailureBase())
      ..registerWarningRule(ThrowOnlyFailureTypes())
      ..registerWarningRule(NoBareCatchConversion())
      ..registerWarningRule(NoErrorToText());
    registry.registerWarningRule(NoStringErrorInState());
  }
}
