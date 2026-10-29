import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';

void main() {
  group('AppSizes', () {
    test('space is based on 8dp grid', () {
      // Before UiScaler init, scale=1.0, so space = 8.0
      expect(AppSizes.space, 8.0);
    });

    test('buttonHeight is 6x space', () {
      expect(AppSizes.buttonHeight, AppSizes.space * 6);
    });

    test('radiusSmall equals one space unit', () {
      expect(AppSizes.radiusSmall, AppSizes.space);
    });

    test('opacityDisabled is 0.38', () {
      expect(AppSizes.opacityDisabled, 0.38);
    });

    test('iconSizes are proportional', () {
      expect(AppSizes.iconSmall, lessThan(AppSizes.iconMedium));
      expect(AppSizes.iconMedium, lessThan(AppSizes.iconLarge));
    });
  });
}
