import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_raw_app_sizes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoRawAppSizesTest);
  });

  test('a trailing * allows a prefix and a plain name allows only itself', () {
    expect(isAllowedMember('fontMini', const ['font*']), isTrue);
    expect(isAllowedMember('space', const ['font*']), isFalse);
    expect(isAllowedMember('space', const ['space']), isTrue);
    expect(isAllowedMember('spaceHalf', const ['space']), isFalse);
  });
}

@reflectiveTest
class NoRawAppSizesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoRawAppSizes();
    super.setUp();
  }

  static const _stub = r'''
class AppSizes {
  AppSizes._();
  static const double space = 8;
  static const double iconSmall = 16;
  static const double fontMini = 12;
}
''';

  Future<void> test_flags_every_scale_read() async {
    const code =
        '''
${_stub}final a = AppSizes.space;
final b = AppSizes.iconSmall;
final c = AppSizes.fontMini;
''';
    await assertDiagnostics(code, [
      lint(code.indexOf('AppSizes.space'), 'AppSizes.space'.length),
      lint(code.indexOf('AppSizes.iconSmall'), 'AppSizes.iconSmall'.length),
      lint(code.indexOf('AppSizes.fontMini'), 'AppSizes.fontMini'.length),
    ]);
  }

  Future<void> test_ignores_other_types_with_a_space_member() async {
    await assertNoDiagnostics('''
class Other {
  static const double space = 1;
}
final a = Other.space;
''');
  }
}
