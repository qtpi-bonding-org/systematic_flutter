import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_inline_widget_composition_in_pages.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoInlineWidgetCompositionInPagesTest);
  });
}

const _stubs = r'''
class Widget {
  const Widget();
}

class BuildContext {}

abstract class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context);
}

class Padding extends Widget {
  Padding({required Widget child});
}

class MultiBlocProvider extends Widget {
  MultiBlocProvider({required List<Widget> providers, required Widget child});
}

class BlocProvider extends Widget {
  BlocProvider({required Widget Function(BuildContext) create});
}
''';

@reflectiveTest
class NoInlineWidgetCompositionInPagesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoInlineWidgetCompositionInPages();
    super.setUp();
  }

  Future<void> test_flags_banned_widget_inline_in_screen_build() async {
    var path = '$testPackageLibPath/pages/bad_inline_screen.dart';
    newFile(path, '''
$_stubs
class BadInlineScreen extends StatelessWidget {
  const BadInlineScreen();

  @override
  Widget build(BuildContext context) {
    return Padding(child: const Widget());
  }
}
''');
    await assertDiagnosticsInFile(path, [lint(610, 30)]);
  }

  Future<void> test_does_not_flag_wiring_widgets() async {
    var path = '$testPackageLibPath/pages/good_wiring_screen.dart';
    newFile(path, '''
$_stubs
class GoodWiringScreen extends StatelessWidget {
  const GoodWiringScreen();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => const Widget())],
      child: const Widget(),
    );
  }
}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_does_not_flag_screen_named_class_in_widgets_dir() async {
    var path = '$testPackageLibPath/pages/widgets/allowed_inline_widget.dart';
    newFile(path, '''
$_stubs
class NotReallyAScreen extends StatelessWidget {
  const NotReallyAScreen();

  @override
  Widget build(BuildContext context) {
    return Padding(child: const Widget());
  }
}
''');
    await assertNoDiagnosticsInFile(path);
  }
}
