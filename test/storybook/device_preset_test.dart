// test/storybook/device_preset_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  group('DevicePreset', () {
    test('iphone16 is the 393dp baseline', () {
      expect(DevicePreset.iphone16.width, 393.0);
    });

    test('defaults run phone -> desktop in ascending width', () {
      final widths = DevicePreset.defaults.map((d) => d.width).toList();
      expect(widths, [375.0, 393.0, 430.0, 820.0, 1200.0]);
    });
  });
}