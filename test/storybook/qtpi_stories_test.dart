import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  group('qtpiStories', () {
    test('includes Tokens and Structures categories', () {
      final stories = qtpiStories({'color1': const Color(0xFF0B152C)});
      final cats = stories.map((s) => s.category).toSet();
      expect(cats, containsAll(['Tokens', 'Structures']));
    });

    test('a colors story builds without throwing', () {
      final stories = qtpiStories({'color1': const Color(0xFF0B152C)});
      final colors = stories.firstWhere((s) => s.name == 'Colors');
      expect(colors.builder, isNotNull);
    });
  });
}