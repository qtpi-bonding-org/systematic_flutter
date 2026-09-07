import 'package:test/test.dart';

import 'package:flutter_ui_lints/src/rules/no_hardcoded_font_size.dart';

import '../rule_test_harness.dart';

void main() {
  test('flags any fontSize: argument', () async {
    final rule = const NoHardcodedFontSize();
    final errors =
        await lintFixture(rule, 'no_hardcoded_font_size_fixture.dart');

    expect(errors, hasLength(1));
    expect(errors.single.errorCode.name, 'no_hardcoded_font_size');
  });
}
