import 'package:test/test.dart';

import 'package:flutter_ui_lints/src/rules/no_hardcoded_colors.dart';

import '../rule_test_harness.dart';

void main() {
  test('flags Color(...) construction, Colors.*, and AppPalette.*', () async {
    final rule = NoHardcodedColors(bannedTypes: ['Colors', 'AppPalette']);
    final errors =
        await lintFixture(rule, 'no_hardcoded_colors_fixture.dart');

    final lines = errors
        .map((e) => lineNumberOf(e, 'no_hardcoded_colors_fixture.dart'))
        .toSet();
    expect(lines, {17, 26, 35});
    expect(errors, hasLength(3));
    expect(errors.every((e) => e.errorCode.name == 'no_hardcoded_colors'),
        isTrue);
  });

  test('an empty bannedTypes list only catches the Color(...) constructor',
      () async {
    final rule = NoHardcodedColors(bannedTypes: []);
    final errors =
        await lintFixture(rule, 'no_hardcoded_colors_fixture.dart');
    // Colors.red and AppPalette.red are no longer banned; only the
    // Color(0xFF00FF00) constructor call (which isn't gated by
    // bannedTypes at all) still gets flagged.
    expect(errors, hasLength(1));
  });
}
