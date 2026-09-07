import 'package:test/test.dart';

import 'package:flutter_ui_lints/src/rules/no_raw_sizedbox_spacing.dart';

import '../rule_test_harness.dart';

void main() {
  test('flags a spacing SizedBox outside VSpace/HSpace', () async {
    final rule = NoRawSizedBoxSpacing(
      allowedEnclosingClasses: ['_LocalVSpace', '_LocalHSpace'],
    );
    final errors =
        await lintFixture(rule, 'no_raw_sizedbox_spacing_fixture.dart');

    expect(errors, hasLength(1));
    expect(errors.single.errorCode.name, 'no_raw_sizedbox_spacing');
  });
}
