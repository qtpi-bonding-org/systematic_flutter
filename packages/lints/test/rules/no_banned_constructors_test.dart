import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:systematic_lints/src/rules/no_banned_constructors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoBannedConstructorsTest);
    defineReflectiveTests(NoBannedConstructorsNothingConfiguredTest);
  });

  test('a type name bans every constructor, Type.name bans one', () {
    expect(isBannedConstruction('Box', null, const ['Box']), isTrue);
    expect(isBannedConstruction('Box', 'circular', const ['Box']), isTrue);
    expect(
      isBannedConstruction('Radius', 'circular', const ['Radius.circular']),
      isTrue,
    );
    expect(
      isBannedConstruction('Radius', 'zero', const ['Radius.circular']),
      isFalse,
    );
    expect(isBannedConstruction('Other', null, const ['Box']), isFalse);
  });
}

const _stub = r'''
class Box {
  const Box();
}

class Radius {
  const Radius();
  const Radius.circular(double r);
  const Radius.zero();
}
''';

@reflectiveTest
class NoBannedConstructorsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoBannedConstructors(banned: const ['Box', 'Radius.circular']);
    super.setUp();
  }

  Future<void> test_flags_banned_type_and_banned_named_constructor() async {
    const code =
        '''
${_stub}final a = const Box();
final b = const Radius.circular(4);
final c = const Radius.zero();
''';
    await assertDiagnostics(code, [
      lint(code.lastIndexOf('const Box()'), 'const Box()'.length),
      lint(
        code.indexOf('const Radius.circular(4)'),
        'const Radius.circular(4)'.length,
      ),
    ]);
  }
}

@reflectiveTest
class NoBannedConstructorsNothingConfiguredTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoBannedConstructors(banned: const []);
    super.setUp();
  }

  Future<void> test_does_nothing_without_a_list() async {
    await assertNoDiagnostics('''
${_stub}final a = const Box();
''');
  }
}
