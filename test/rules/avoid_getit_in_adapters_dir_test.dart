import 'package:analyzer/src/diagnostic/diagnostic.dart' // ignore: implementation_imports
    as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_lint_generator/src/rules/avoid_getit_in_adapters_dir.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// See avoid_bloc_imports_in_widgets_dir_test.dart for why the
// uri_does_not_exist error has to be listed alongside the lint here.
const _uriError = diag.uriDoesNotExist;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidGetItInAdaptersDirTest);
  });
}

@reflectiveTest
class AvoidGetItInAdaptersDirTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidGetItInAdaptersDir();
    super.setUp();
  }

  Future<void> test_flags_getit_import_in_adapters_dir() async {
    var path = '$testPackageLibPath/adapters/my_adapter.dart';
    newFile(path, r'''
import 'package:get_it/get_it.dart';
''');
    await assertDiagnosticsInFile(path, [lint(0, 36), error(_uriError, 7, 28)]);
  }

  Future<void> test_does_not_flag_outside_adapters_dir() async {
    var path = '$testPackageLibPath/other/my_file.dart';
    newFile(path, r'''
import 'package:get_it/get_it.dart';
''');
    await assertDiagnosticsInFile(path, [error(_uriError, 7, 28)]);
  }
}
