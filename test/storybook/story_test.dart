import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  Story story(String cat, String name) =>
      Story(category: cat, name: name, builder: (_) => const SizedBox());

  group('groupStories', () {
    test('groups by category preserving first-seen order', () {
      final grouped = groupStories([
        story('Tokens', 'Colors'),
        story('Structures', 'DsRow'),
        story('Tokens', 'Spacing'),
      ]);
      expect(grouped.map((g) => g.name).toList(), ['Tokens', 'Structures']);
      expect(grouped.first.stories.map((s) => s.name).toList(),
          ['Colors', 'Spacing']);
    });

    test('empty input yields empty list', () {
      expect(groupStories(const []), isEmpty);
    });
  });
}
