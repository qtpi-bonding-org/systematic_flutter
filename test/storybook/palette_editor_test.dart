// test/storybook/palette_editor_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_color_palette/flutter_color_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  testWidgets('typing a hex updates the controller token', (tester) async {
    final controller = StorybookThemeController(ThemeService(
      lightPalette: AppColorPalette(
        colors: {'color1': const Color(0xFF0B152C)},
        name: 'T',
      ),
    ));

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PaletteEditor(controller: controller)),
    ));

    expect(find.text('color1'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'FF00C3FF');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.tokens['color1'], const Color(0xFF00C3FF));
  });
}
