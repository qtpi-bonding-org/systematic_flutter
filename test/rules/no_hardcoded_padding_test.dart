import 'package:test/test.dart';

import 'package:flutter_ui_lints/src/rules/no_hardcoded_padding.dart';

import '../rule_test_harness.dart';

void main() {
  test('flags raw numeric EdgeInsets arguments, not scaled tokens',
      () async {
    final rule = const NoHardcodedPadding();
    final errors =
        await lintFixture(rule, 'no_hardcoded_padding_fixture.dart');

    // BadRawPadding contributes 1 (EdgeInsets.all(16)); BadRawOnlyPadding
    // contributes 2 (left: 4, bottom: 8).
    expect(errors, hasLength(3));
    expect(errors.every((e) => e.errorCode.name == 'no_hardcoded_padding'),
        isTrue);
  });
}
