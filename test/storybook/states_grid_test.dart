// test/storybook/states_grid_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qtpi_ui/storybook.dart';

void main() {
  testWidgets('renders a labeled cell per state', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatesGrid(states: {
          'default': (_) => const Text('A'),
          'disabled': (_) => const Text('B'),
        }),
      ),
    ));
    expect(find.text('default'), findsOneWidget);
    expect(find.text('disabled'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}
