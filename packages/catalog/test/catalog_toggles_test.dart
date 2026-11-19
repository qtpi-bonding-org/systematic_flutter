import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:systematic_catalog/systematic_catalog.dart';

ThemeData _theme(CatalogTokens t, Brightness b) =>
    ThemeData(colorSchemeSeed: t.seed, brightness: b);

Widget _probe(BuildContext c) {
  final mq = MediaQuery.of(c);
  return SizedBox(
    width: 1000,
    child: Text(
      'scale:${mq.textScaler.scale(10)} '
      'dir:${Directionality.of(c).name} '
      'w:${mq.size.width.round()}',
    ),
  );
}

Widget _app(List<CatalogEntry> entries,
    {ThemeData Function(CatalogTokens, Brightness)? themeBuilder,
    Map<String, Color> paletteColors = const {}}) {
  return MaterialApp(
    home: CatalogPage(
      entries: entries,
      themeBuilder: themeBuilder ?? _theme,
      paletteColors: paletteColors,
    ),
  );
}

void bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(3000, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _widgetEntry = CatalogEntry(
  name: 'Probe',
  kind: CatalogKind.widget,
  states: {'only': _probe},
);

void main() {
  group('CatalogEntry.fromSamples', () {
    test('makes one state per sample, built from that sample', () {
      final entry = CatalogEntry.fromSamples<int>(
        name: 'Count',
        kind: CatalogKind.widget,
        samples: const {'one': 1, 'two': 2},
        build: (n) => Text('n=$n'),
      );
      expect(entry.name, 'Count');
      expect(entry.kind, CatalogKind.widget);
      expect(entry.states.keys, ['one', 'two']);
    });

    testWidgets('page shows one tile per named sample', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(_app([
        CatalogEntry.fromSamples<String>(
          name: 'Label',
          kind: CatalogKind.widget,
          samples: const {'short': 'hi', 'long': 'a much longer text'},
          build: (s) => Text('v:$s'),
        ),
      ]));
      expect(find.text('Label / short'), findsOneWidget);
      expect(find.text('Label / long'), findsOneWidget);
      expect(find.text('v:hi'), findsNWidgets(2)); // light and dark
      expect(find.text('v:a much longer text'), findsNWidgets(2));
    });
  });

  group('display toggles', () {
    testWidgets('default: normal scale, ltr, wide', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(_app(const [_widgetEntry]));
      expect(find.textContaining('scale:10.0 dir:ltr'), findsNWidgets(2));
    });

    testWidgets('large text applies scale 2.0 to every tile', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(_app(const [_widgetEntry]));
      await tester.tap(find.byKey(const Key('catalog.toggle.largeText')));
      await tester.pump();
      expect(find.textContaining('scale:20.0'), findsNWidgets(2));
      await tester.tap(find.byKey(const Key('catalog.toggle.largeText')));
      await tester.pump();
      expect(find.textContaining('scale:10.0'), findsNWidgets(2));
    });

    testWidgets('narrow limits widget tiles to 320 and reports it',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(_app(const [_widgetEntry]));
      await tester.tap(find.byKey(const Key('catalog.toggle.narrow')));
      await tester.pump();
      expect(tester.getSize(find.byKey(const Key('Probe/only/light'))).width,
          320);
      expect(find.textContaining('w:320'), findsNWidgets(2));
    });

    testWidgets('narrow also narrows screen frames', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(_app(const [
        CatalogEntry(
            name: 'Scr', kind: CatalogKind.screen, states: {'a': _probe}),
      ]));
      await tester.tap(find.byKey(const Key('catalog.toggle.narrow')));
      await tester.pump();
      expect(find.textContaining('w:320'), findsNWidgets(2));
      expect(tester.getSize(find.byKey(const Key('Scr/a/light'))).width,
          closeTo(320 * 0.4, 0.5));
    });

    testWidgets('right-to-left sets Directionality for every tile',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(_app(const [_widgetEntry]));
      await tester.tap(find.byKey(const Key('catalog.toggle.rtl')));
      await tester.pump();
      expect(find.textContaining('dir:rtl'), findsNWidgets(2));
    });
  });

  group('tokens', () {
    testWidgets('spacing and size sliders reach the themeBuilder',
        (tester) async {
      bigScreen(tester);
      final spacing = <double>[];
      final sizes = <double>[];
      await tester.pumpWidget(_app(const [_widgetEntry], themeBuilder: (t, b) {
        spacing.add(t.spacingScale);
        sizes.add(t.sizeScale);
        return _theme(t, b);
      }));
      expect(spacing.last, 1.0);
      expect(sizes.last, 1.0);
      final s = tester.getRect(find.byKey(const Key('catalog.spacingScale')));
      await tester.tapAt(Offset(s.right - 1, s.center.dy));
      await tester.pump();
      expect(spacing.last, greaterThan(1.4));
      final z = tester.getRect(find.byKey(const Key('catalog.sizeScale')));
      await tester.tapAt(Offset(z.right - 1, z.center.dy));
      await tester.pump();
      expect(sizes.last, greaterThan(1.4));
    });

    testWidgets('spacing no longer moves the catalog\'s own tile gaps',
        (tester) async {
      bigScreen(tester);
      const two = CatalogEntry(
        name: 'Two',
        kind: CatalogKind.widget,
        states: {'a': _small, 'b': _small},
      );
      await tester.pumpWidget(_app(const [two]));
      double gap() =>
          tester.getTopLeft(find.text('Two / b')).dx -
          tester.getTopRight(find.byKey(const Key('Two/a/dark'))).dx;
      final before = gap();
      final s = tester.getRect(find.byKey(const Key('catalog.spacingScale')));
      await tester.tapAt(Offset(s.right - 1, s.center.dy));
      await tester.pump();
      expect(gap(), before);
    });

    testWidgets('palette colour swatches pass overrides to the themeBuilder',
        (tester) async {
      bigScreen(tester);
      final seen = <Map<String, Color>>[];
      await tester.pumpWidget(_app(
        const [_widgetEntry],
        paletteColors: const {'color1': Color(0xFF2196F3)},
        themeBuilder: (t, b) {
          seen.add(t.colorOverrides);
          return _theme(t, b);
        },
      ));
      expect(seen.last, isEmpty);
      await tester.tap(find.byKey(const Key('catalog.color.color1.1')));
      await tester.pump();
      expect(seen.last.keys, ['color1']);
      expect(seen.last['color1'], isNot(const Color(0xFF2196F3)));
    });

    test('CatalogTokens equality covers the new fields', () {
      const a = CatalogTokens();
      expect(a.copyWith(sizeScale: 1.2), isNot(a));
      expect(a.copyWith(colorOverrides: {'c': Colors.red}), isNot(a));
      expect(a.copyWith(sizeScale: 1.2), a.copyWith(sizeScale: 1.2));
    });
  });
}

Widget _small(BuildContext c) => const SizedBox(width: 50, height: 20);
