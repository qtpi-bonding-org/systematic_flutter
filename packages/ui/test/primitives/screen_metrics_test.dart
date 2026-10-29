import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_ui/systematic_ui.dart';

void main() {
  group('UiScaler.initFrom', () {
    test('FixedScreenMetrics at baseline width yields scaleFactor 1.0', () {
      UiScaler.instance.initFrom(const FixedScreenMetrics(393.0));
      expect(UiScaler.instance.scaleFactor, 1.0);
    });

    test('wider width scales up, clamped to 1.15', () {
      UiScaler.instance.initFrom(const FixedScreenMetrics(820.0)); // iPad
      expect(UiScaler.instance.scaleFactor, 1.15);
    });

    test('narrower width scales down, clamped to 0.85', () {
      UiScaler.instance.initFrom(const FixedScreenMetrics(200.0));
      expect(UiScaler.instance.scaleFactor, 0.85);
    });

    test('px multiplies by the simulated factor', () {
      UiScaler.instance.initFrom(const FixedScreenMetrics(393.0));
      expect(UiScaler.instance.px(10.0), 10.0);
    });
  });
}
