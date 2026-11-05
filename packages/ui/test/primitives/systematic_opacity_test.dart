import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_ui/systematic_ui.dart';

void main() {
  Future<SystematicOpacity> seenBy(
    WidgetTester tester, {
    SystematicOpacity? opacity,
  }) async {
    late SystematicOpacity seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: opacity == null ? null : ThemeData(extensions: [opacity]),
        home: Builder(
          builder: (context) {
            seen = context.opacity;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return seen;
  }

  testWidgets('a bare app gets the AppSizes opacity scale', (tester) async {
    final seen = await seenBy(tester);
    expect(seen.hover, AppSizes.opacityHover);
    expect(seen.inactive, AppSizes.opacityInactive);
    expect(seen.disabled, AppSizes.opacityDisabled);
    expect(seen.ghost, AppSizes.opacityGhost);
    expect(seen.full, AppSizes.opacityFull);
  });

  testWidgets('a theme changes how faint disabled is', (tester) async {
    final seen = await seenBy(
      tester,
      opacity: const SystematicOpacity.standard().copyWith(disabled: 0.2),
    );
    expect(seen.disabled, 0.2);
    expect(seen.ghost, AppSizes.opacityGhost);
  });
}
