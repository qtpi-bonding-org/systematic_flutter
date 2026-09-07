import 'package:test/test.dart';

import 'package:flutter_ui_lints/src/rules/no_hardcoded_font_family.dart';

import '../rule_test_harness.dart';

void main() {
  test('flags a fontFamily: not routed through an allowed type', () async {
    final rule = NoHardcodedFontFamily(allowedTypes: ['AppFonts']);
    final errors =
        await lintFixture(rule, 'no_hardcoded_font_family_fixture.dart');

    expect(errors, hasLength(1));
    expect(errors.single.errorCode.name, 'no_hardcoded_font_family');
  });
}
