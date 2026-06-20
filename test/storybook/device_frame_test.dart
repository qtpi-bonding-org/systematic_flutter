// test/storybook/device_frame_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  testWidgets('preset drives UiScaler to the device width factor',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeviceFrame(
          preset: DevicePreset.ipad, // 820 -> clamps to 1.15
          child: const SizedBox(),
        ),
      ),
    ));
    expect(UiScaler.instance.scaleFactor, 1.15);
  });

  testWidgets('renders its child', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DeviceFrame(
          preset: DevicePreset.iphone16,
          child: const Text('stage'),
        ),
      ),
    ));
    expect(find.text('stage'), findsOneWidget);
  });
}
