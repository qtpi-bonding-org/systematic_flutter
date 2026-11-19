import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_catalog/systematic_catalog.dart';

ThemeData _theme(CatalogTokens t, Brightness b) => ThemeData(
      colorSchemeSeed: t.seed,
      brightness: b,
      fontFamily: t.fontFamily,
    );

Widget _app(List<CatalogEntry> entries,
    {ThemeData Function(CatalogTokens, Brightness)? themeBuilder}) {
  return MaterialApp(
    home: CatalogPage(
      entries: entries,
      themeBuilder: themeBuilder ?? _theme,
    ),
  );
}

Widget _brightnessText(BuildContext c) =>
    Text('b:${Theme.of(c).brightness.name}');

void main() {
  setUp(() {});

  const entries = [
    CatalogEntry(
      name: 'Home',
      kind: CatalogKind.screen,
      states: {'empty': _brightnessText},
    ),
    CatalogEntry(
      name: 'Button',
      kind: CatalogKind.widget,
      states: {'enabled': _brightnessText, 'disabled': _brightnessText},
    ),
  ];

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(2400, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('widgets section is above screens section', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(_app(entries));
    final w = tester.getTopLeft(find.text('Widgets')).dy;
    final s = tester.getTopLeft(find.text('Screens')).dy;
    expect(w, lessThan(s));
    expect(tester.getTopLeft(find.text('Button / enabled')).dy,
        lessThan(tester.getTopLeft(find.text('Home / empty')).dy));
  });

  testWidgets('each state appears in light and dark', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(_app(entries));
    expect(find.text('Button / enabled'), findsOneWidget);
    expect(find.text('Button / disabled'), findsOneWidget);
    expect(find.text('Home / empty'), findsOneWidget);
    expect(find.text('b:light'), findsNWidgets(3));
    expect(find.text('b:dark'), findsNWidgets(3));
    final light = tester.getTopLeft(find.byKey(const Key('Button/enabled/light')));
    final dark = tester.getTopLeft(find.byKey(const Key('Button/enabled/dark')));
    expect(dark.dx, greaterThan(light.dx));
    expect(dark.dy, light.dy);
  });

  testWidgets('changing font scale changes the theme tiles get',
      (tester) async {
    bigScreen(tester);
    final seen = <double>[];
    await tester.pumpWidget(_app(entries, themeBuilder: (t, b) {
      seen.add(t.fontScale);
      return _theme(t, b);
    }));
    expect(seen.last, 1.0);
    final slider = find.byKey(const Key('catalog.fontScale'));
    final rect = tester.getRect(slider);
    await tester.tapAt(Offset(rect.right - 1, rect.center.dy));
    await tester.pump();
    expect(seen.last, greaterThan(1.3));
  });

  testWidgets('changing a swatch changes the seed', (tester) async {
    bigScreen(tester);
    final seeds = <Color>[];
    await tester.pumpWidget(_app(entries, themeBuilder: (t, b) {
      seeds.add(t.seed);
      return _theme(t, b);
    }));
    final first = seeds.last;
    await tester.tap(find.byKey(const Key('catalog.swatch.1')));
    await tester.pump();
    expect(seeds.last, isNot(first));
  });

  testWidgets('a throwing builder shows an error tile', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(_app([
      CatalogEntry(
        name: 'Bad',
        kind: CatalogKind.widget,
        states: {'boom': (_) => throw StateError('kaput')},
      ),
      ...entries,
    ]));
    expect(find.textContaining('kaput'), findsWidgets);
    expect(find.text('Button / enabled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('screens render inside fixed frames', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(_app(entries));
    final frame = find.byKey(const Key('Home/empty/light'));
    expect(frame, findsOneWidget);
    final size = tester.getSize(frame);
    expect(size.width, closeTo(390 * 0.4, 0.5));
    expect(size.height, closeTo(844 * 0.4, 0.5));
    final w = tester.getSize(find.byKey(const Key('Button/enabled/light')));
    expect(w.width, lessThanOrEqualTo(360));
  });
}
