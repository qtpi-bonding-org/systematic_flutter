import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n_key_resolver/testing.dart';
import 'package:spike_app/theme/app_theme.dart';
import 'package:systematic_ui/systematic_ui.dart';

import 'helpers.dart';

void main() {
  test('the theme comes from the palette and carries the size tokens', () {
    final theme = AppTheme.build(
      palette: kPalette,
      sizes: const SystematicSizes.standard(),
      brightness: Brightness.light,
    );
    expect(theme.colorScheme.primary, kPalette.getColor('color1'));
    expect(theme.extension<SystematicSizes>(), isNotNull);
    expect(theme.brightness, Brightness.light);
  });

  test('ThemeService overrides change the theme colour', () {
    final service = ThemeService(
      lightPalette: kPalette,
      darkPalette: kPalette.symmetricPalette,
    );
    const red = Color(0xFFFF0000);
    service.setOverride('color1', red);
    final theme = AppTheme.build(
      palette: service.currentPalette,
      sizes: const SystematicSizes.standard(),
      brightness: Brightness.light,
    );
    expect(theme.colorScheme.primary, red);
  });

  test('a larger space token gives larger presets', () {
    const small = SystematicSizes.standard();
    final big = small.copyWith(space: 16);
    expect(PaddingSpace(big).card.left, greaterThan(PaddingSpace(small).card.left));
  });

  testWidgets('the app uses the palette colour', (t) async {
    await pumpApp(t);
    final theme = Theme.of(t.element(find.byType(TextButton).first));
    expect(theme.colorScheme.primary, kPalette.getColor('color1'));
    await unmountApp(t);
  });

  testWidgets('the app has a dark theme and follows the system mode',
      (t) async {
    await pumpApp(t);
    final app = t.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme!.brightness, Brightness.light);
    expect(app.darkTheme!.brightness, Brightness.dark);
    expect(app.darkTheme!.colorScheme.primary,
        kPalette.symmetricPalette.getColor('color1'));
    expect(app.darkTheme!.colorScheme.onSurface,
        kPalette.symmetricPalette.getColor('neutral1'));
    expect(app.darkTheme!.extension<SystematicSizes>(), isNotNull);
    await unmountApp(t);
  });

  test('no handwritten L10nKeys or DataText in lib', () {
    assertNoHandwrittenKeys('lib');
  });
}
