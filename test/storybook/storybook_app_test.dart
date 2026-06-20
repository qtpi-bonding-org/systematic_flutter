// test/storybook/storybook_app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  testWidgets('renders sidebar entries and the selected story', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    final controller = StorybookThemeController(ThemeService(
      lightPalette: AppColorPalette(
        colors: {'color1': const Color(0xFF0B152C)},
        name: 'T',
      ),
    ));

    await tester.pumpWidget(StorybookApp(
      controller: controller,
      themeBuilder: (_) => ThemeData.dark(),
      stories: [
        Story(
          category: 'Tokens',
          name: 'Colors',
          builder: (_) => const Text('color-gallery'),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tokens'), findsOneWidget);
    expect(find.text('Colors'), findsWidgets);
    expect(find.text('color-gallery'), findsOneWidget);
  });
}
