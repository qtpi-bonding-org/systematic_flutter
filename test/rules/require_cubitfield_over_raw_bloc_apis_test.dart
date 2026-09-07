import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_lint_generator/src/rules/require_cubitfield_over_raw_bloc_apis.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

const _stubs = r'''
class BuildContext {
  T watch<T>() => this as T;
  T select<T>(Object selector) => this as T;
}

class BlocBuilder {
  BlocBuilder();
}

class BlocSelector {
  BlocSelector();
}

class BlocConsumer {
  BlocConsumer();
}
''';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RequireCubitFieldOverRawBlocApisTest);
  });
}

@reflectiveTest
class RequireCubitFieldOverRawBlocApisTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = RequireCubitFieldOverRawBlocApis();
    super.setUp();
  }

  Future<void> test_flags_context_watch_and_bare_bloc_builder() async {
    var path = '$testPackageLibPath/my_view.dart';
    newFile(path, '''
$_stubs
void build(BuildContext context) {
  context.watch<int>();
  BlocBuilder();
}
''');
    await assertDiagnosticsInFile(path, [lint(259, 20), lint(283, 13)]);
  }

  Future<void> test_does_not_flag_cubit_adapter_file() async {
    var path = '$testPackageLibPath/cubit_adapter.dart';
    newFile(path, '''
$_stubs
void build(BuildContext context) {
  context.watch<int>();
  BlocBuilder();
}
''');
    await assertNoDiagnosticsInFile(path);
  }
}
