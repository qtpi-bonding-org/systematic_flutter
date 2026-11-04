import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_ui/systematic_ui.dart';

void main() {
  const compact = SystematicSizes(
    space: 10,
    spaceHalf: 5,
    radiusTiny: 1,
    radiusSmall: 3,
    radiusMedium: 6,
    radiusLarge: 9,
  );

  Widget app(Widget child, {SystematicSizes? sizes}) => MaterialApp(
    theme: sizes == null ? null : ThemeData(extensions: [sizes]),
    home: Scaffold(body: child),
  );

  group('SystematicSizes', () {
    testWidgets('a bare app gets the AppSizes scale', (tester) async {
      late SystematicSizes seen;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              seen = context.sizes;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(seen.space, AppSizes.space);
      expect(seen.spaceHalf, AppSizes.spaceHalf);
      expect(seen.radiusMedium, AppSizes.radiusMedium);
    });

    testWidgets('sizes follow the screen scale live, not a snapshot', (
      tester,
    ) async {
      late SystematicSizes seen;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              seen = context.sizes;
              return const SizedBox.shrink();
            },
          ),
          sizes: compact,
        ),
      );
      final before = seen.space;

      UiScaler.instance.initFrom(const FixedScreenMetrics(393 * 1.1));
      addTearDown(
        () => UiScaler.instance.initFrom(const FixedScreenMetrics(393)),
      );

      expect(before, 10);
      expect(seen.space, closeTo(11, 0.0001));
    });

    test('lerp blends the numbers', () {
      final mid = const SystematicSizes.standard().lerp(compact, 0.5);

      expect(mid.space, (AppSizes.space + 10) / 2);
    });
  });

  group('VSpace and HSpace follow the theme', () {
    testWidgets('VSpace.x2 is two theme spaces tall', (tester) async {
      await tester.pumpWidget(app(VSpace.x2, sizes: compact));

      expect(tester.widget<SizedBox>(find.byType(SizedBox).first).height, 20);
    });

    testWidgets('HSpace.x05 is half a theme space wide', (tester) async {
      await tester.pumpWidget(app(HSpace.x05, sizes: compact));

      expect(tester.widget<SizedBox>(find.byType(SizedBox).first).width, 5);
    });

    testWidgets('without a theme the default scale applies', (tester) async {
      await tester.pumpWidget(app(VSpace.x3));

      expect(
        tester.widget<SizedBox>(find.byType(SizedBox).first).height,
        AppSizes.space * 3,
      );
    });

    testWidgets('a Theme changes the spacing for its subtree only', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Column(
            children: [
              VSpace.x1,
              Theme(
                data: ThemeData(extensions: [compact]),
                child: VSpace.x1,
              ),
            ],
          ),
        ),
      );

      final heights = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((b) => b.height != null && b.width == null)
          .map((b) => b.height)
          .toList();
      expect(heights, [AppSizes.space, 10]);
    });
  });

  group('context.padding follows the theme', () {
    testWidgets('card padding is two theme spaces on every side', (
      tester,
    ) async {
      late EdgeInsets card;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              card = context.padding.card;
              return const SizedBox.shrink();
            },
          ),
          sizes: compact,
        ),
      );

      expect(card, const EdgeInsets.all(20));
    });

    testWidgets('listItem is one space vertical and two horizontal', (
      tester,
    ) async {
      late EdgeInsets item;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              item = context.padding.listItem;
              return const SizedBox.shrink();
            },
          ),
          sizes: compact,
        ),
      );

      expect(item, const EdgeInsets.symmetric(vertical: 10, horizontal: 20));
    });
  });
}
