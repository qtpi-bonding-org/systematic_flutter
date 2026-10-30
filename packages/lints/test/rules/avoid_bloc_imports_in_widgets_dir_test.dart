import 'package:analyzer/src/diagnostic/diagnostic.dart' // ignore: implementation_imports
    as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/avoid_bloc_imports_in_widgets_dir.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// The fixtures below import a real, unresolvable package URI on purpose --
// this rule matches on the literal URI string, not a resolved package, so
// the import never needs to actually resolve. The resulting
// "uri_does_not_exist" error has to be listed alongside our own lint,
// though, or assertDiagnostics treats it as an unexpected diagnostic.
const _uriError = diag.uriDoesNotExist;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidBlocImportsInWidgetsDirTest);
  });
}

@reflectiveTest
class AvoidBlocImportsInWidgetsDirTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBlocImportsInWidgetsDir();
    super.setUp();
  }

  Future<void> test_flags_bloc_import_in_widgets_dir() async {
    var path = '$testPackageLibPath/widgets/my_widget.dart';
    newFile(path, r'''
import 'package:flutter_bloc/flutter_bloc.dart';
''');
    await assertDiagnosticsInFile(path, [lint(0, 48), error(_uriError, 7, 40)]);
  }

  Future<void> test_does_not_flag_outside_widgets_dir() async {
    var path = '$testPackageLibPath/other/my_file.dart';
    newFile(path, r'''
import 'package:flutter_bloc/flutter_bloc.dart';
''');
    await assertDiagnosticsInFile(path, [error(_uriError, 7, 40)]);
  }
}
