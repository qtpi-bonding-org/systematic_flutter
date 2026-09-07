import 'package:test/test.dart';

import 'package:flutter_ui_lints/src/rules/no_hardcoded_strings.dart';

import '../rule_test_harness.dart';

void main() {
  test('flags a string literal passed to Text(...)', () async {
    final rule = NoHardcodedStrings(allowedTypes: ['MessageKey']);
    final errors =
        await lintFixture(rule, 'no_hardcoded_strings_fixture.dart');

    expect(errors, hasLength(1));
    expect(errors.single.errorCode.name, 'no_hardcoded_strings');
  });
}
