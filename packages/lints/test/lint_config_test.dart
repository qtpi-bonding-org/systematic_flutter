import 'package:systematic_lints/src/lint_config.dart';
import 'package:test/test.dart';

void main() {
  group('options', () {
    final config = LintConfig.parse('''
no_hardcoded_colors:
  banned_types: [Colors, Palette]
no_inline_widget_composition_in_pages:
  page_suffix: Page
''');

    test('reads a list and a string', () {
      expect(config.list('no_hardcoded_colors', 'banned_types', ['x']), [
        'Colors',
        'Palette',
      ]);
      expect(
        config.string(
          'no_inline_widget_composition_in_pages',
          'page_suffix',
          'Screen',
        ),
        'Page',
      );
    });

    test('falls back when the rule or key is absent', () {
      expect(config.list('no_hardcoded_colors', 'missing', ['x']), ['x']);
      expect(config.string('other_rule', 'k', 'd'), 'd');
    });

    test('empty config gives every fallback', () {
      expect(LintConfig.empty.list('r', 'k', ['a']), ['a']);
    });
  });

  group('paths', () {
    test('tests, generated code and stories are skipped by default', () {
      const config = LintConfig.empty;
      expect(config.appliesTo('r', 'lib/a.dart'), isTrue);
      expect(config.appliesTo('r', 'test/a_test.dart'), isFalse);
      expect(config.appliesTo('r', 'lib/a.g.dart'), isFalse);
      expect(config.appliesTo('r', 'lib/a.freezed.dart'), isFalse);
      expect(config.appliesTo('r', 'lib/a.stories.dart'), isFalse);
    });

    test('a top-level exclude replaces the defaults', () {
      final config = LintConfig.parse('exclude: [lib/legacy/**]');
      expect(config.appliesTo('r', 'lib/legacy/a.dart'), isFalse);
      expect(config.appliesTo('r', 'test/a_test.dart'), isTrue);
    });

    test('a rule exclude adds to the global one', () {
      final config = LintConfig.parse('''
r:
  exclude: [lib/design_system/storybook/**]
''');
      expect(
        config.appliesTo('r', 'lib/design_system/storybook/a.dart'),
        isFalse,
      );
      expect(config.appliesTo('r', 'test/a_test.dart'), isFalse);
      expect(
        config.appliesTo('other', 'lib/design_system/storybook/a.dart'),
        isTrue,
      );
    });

    test('a rule include restricts the rule to those paths', () {
      final config = LintConfig.parse('''
r:
  include: [lib/features/**]
''');
      expect(config.appliesTo('r', 'lib/features/a.dart'), isTrue);
      expect(config.appliesTo('r', 'lib/app/a.dart'), isFalse);
    });

    test('a rule include can turn tests back on', () {
      final config = LintConfig.parse('''
r:
  include: [test/**]
''');
      expect(config.appliesTo('r', 'test/a_test.dart'), isTrue);
    });
  });
}
