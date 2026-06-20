import 'package:flutter/widgets.dart';

/// A single catalog entry: how to build one widget/token demo.
class Story {
  const Story({
    required this.category,
    required this.name,
    required this.builder,
  });

  final String category;
  final String name;
  final WidgetBuilder builder;
}

/// A category with its stories, in first-seen order.
class StoryCategory {
  StoryCategory(this.name) : stories = [];
  final String name;
  final List<Story> stories;
}

/// Groups stories by [Story.category], preserving first-seen order of both
/// categories and stories.
List<StoryCategory> groupStories(List<Story> stories) {
  final byName = <String, StoryCategory>{};
  final order = <StoryCategory>[];
  for (final s in stories) {
    final cat = byName.putIfAbsent(s.category, () {
      final c = StoryCategory(s.category);
      order.add(c);
      return c;
    });
    cat.stories.add(s);
  }
  return order;
}
