import 'package:test/test.dart';

import 'package:flutter_ui_lints/src/rules/no_inline_widget_composition_in_pages.dart';

import '../rule_test_harness.dart';

const _bannedWidgetNames = [
  'Padding', 'Column', 'Row', 'Container', 'SizedBox', 'Text', 'Icon',
  'Stack', 'ListView', 'GridView', 'Align', 'Center', 'Expanded',
  'Flexible', 'Card', 'Scaffold', 'AppBar',
];

NoInlineWidgetCompositionInPages _rule() => NoInlineWidgetCompositionInPages(
      pageSuffix: 'Screen',
      widgetDirNames: const ['widgets', 'adapters'],
      bannedWidgetNames: _bannedWidgetNames,
    );

void main() {
  test('flags banned widgets built inline in a *Screen build()', () async {
    final errors =
        await lintFixture(_rule(), 'pages/bad_inline_screen.dart');

    // Padding and Text are both banned; EdgeInsets.all/AppSizes.space are
    // not widget constructors and must not be flagged by this rule.
    expect(errors, hasLength(2));
    expect(
      errors.every(
        (e) => e.errorCode.name == 'no_inline_widget_composition_in_pages',
      ),
      isTrue,
    );
  });

  test('does not flag provider/DI wiring widgets', () async {
    final errors =
        await lintFixture(_rule(), 'pages/good_wiring_screen.dart');
    expect(errors, isEmpty);
  });

  test('does not flag a *Screen-named class inside a widgets/ directory',
      () async {
    final errors =
        await lintFixture(_rule(), 'pages/widgets/allowed_inline_widget.dart');
    expect(errors, isEmpty);
  });
}
