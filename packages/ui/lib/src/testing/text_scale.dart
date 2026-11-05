import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Text sizes a user can reach with the system accessibility setting: normal,
/// large, and the largest common step.
const List<double> kAccessibilityTextScales = [1.0, 1.5, 2.0];

/// Pumps the widget [build] returns at each text scale and fails, naming the
/// scale, if the framework reported an error (a `RenderFlex` overflow, a
/// layout assertion). Large system text is the usual way a fixed-height row or
/// a tight label breaks, and nothing else in a normal test run exercises it.
///
/// [build] receives the scale so a test can label what it builds. The widget
/// is wrapped in a `MediaQuery` with that scale; wrap your own `MaterialApp`
/// inside [build] as usual (a `MaterialApp` keeps the `MediaQuery` above it).
Future<void> expectNoErrorsAtTextScales(
  WidgetTester tester,
  Widget Function(double scale) build, {
  List<double> scales = kAccessibilityTextScales,
}) async {
  for (final scale in scales) {
    await tester.pumpWidget(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: build(scale),
        ),
      ),
    );
    await tester.pump();
    final error = tester.takeException();
    expect(
      error,
      isNull,
      reason: 'a layout error at text scale ${scale}x: $error',
    );
  }
}
