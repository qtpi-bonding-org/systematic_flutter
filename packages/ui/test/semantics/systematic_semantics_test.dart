import 'dart:ui' show Tristate;

import 'package:qtpi_ui/qtpi_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n_key_resolver/runtime.dart';

/// Resolves keys by looking them up in [strings]; data is shown as is.
class _MapResolver implements LabelResolver {
  _MapResolver(this.strings);
  final Map<String, String> strings;

  @override
  String resolve(Label label) => switch (label) {
        L10nKey(:final key) => strings[key] ?? key,
        DataText(:final value) => value,
      };
}

Widget _host(Widget child, {LabelResolver? resolver}) => LabelScope(
      resolver: resolver ?? _MapResolver({}),
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  group('ControlId', () {
    test('accepts snake case, dots, colons and dashes', () {
      expect(ControlId.isValid('save'), isTrue);
      expect(ControlId.isValid('tab_rail.close'), isTrue);
      expect(ControlId.isValid('task_graph_node_modal_view_in_lane'), isTrue);
      expect(ControlId.isValid('note_row:abc-123'), isTrue);
    });

    test('accepts existing camelCase test keys', () {
      expect(ControlId.isValid('settingsButton'), isTrue);
      expect(ControlId.isValid('folder-node-modal-new-note-button'), isTrue);
    });

    test('rejects empty and whitespace', () {
      expect(ControlId.isValid(''), isFalse);
      expect(ControlId.isValid('Save Button'), isFalse);
      expect(ControlId.isValid(' save'), isFalse);
    });

    test('item joins group and item id', () {
      expect(ControlId.item('note_row', 'abc').value, 'note_row:abc');
    });

    test('item asserts on an invalid part', () {
      expect(() => ControlId.item('note_row', ''), throwsAssertionError);
    });
  });

  group('SpokenText', () {
    testWidgets('an empty DataText label is rejected when built', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SystematicSemantics(
            id: ControlId('save'),
            text: SpokenText(label: DataText('')),
            behavior: ControlBehavior(role: ControlRole.button),
            child: SizedBox(width: 80, height: 48),
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    test('value equality', () {
      expect(const SpokenText(label: DataText('Save')),
          const SpokenText(label: DataText('Save')));
      expect(
        const SpokenText(label: DataText('Save')),
        isNot(const SpokenText(
            label: DataText('Save'), hint: DataText('Saves the note'))),
      );
    });
  });

  group('ControlBehavior', () {
    test('a tab must say whether it is selected', () {
      expect(
        () => ControlBehavior(role: ControlRole.tab),
        throwsAssertionError,
      );
      expect(
        const ControlBehavior(role: ControlRole.tab, selected: false).selected,
        isFalse,
      );
    });

    test('status and alert cannot also be live regions', () {
      expect(
        () => ControlBehavior(role: ControlRole.status, liveRegion: true),
        throwsAssertionError,
      );
      expect(
        () => ControlBehavior(role: ControlRole.alert, liveRegion: true),
        throwsAssertionError,
      );
    });

    test('a switch needs toggled and a checkbox needs checked', () {
      expect(
        () => ControlBehavior(role: ControlRole.switchToggle),
        throwsAssertionError,
      );
      expect(
        () => ControlBehavior(role: ControlRole.checkbox),
        throwsAssertionError,
      );
    });
  });

  group('SystematicSemantics', () {
    testWidgets('exposes identifier, label, button role and tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          SystematicSemantics(
            id: const ControlId('save'),
            text: const SpokenText(label: DataText('Save')),
            behavior: const ControlBehavior(role: ControlRole.button),
            onTap: () => taps++,
            child: const SizedBox(width: 80, height: 48),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsIdentifier('save')),
        matchesSemantics(
          identifier: 'save',
          label: 'Save',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      tester.semantics.tap(find.semantics.byLabel('Save'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('the id is also a Key, so find.byKey keeps working', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SystematicSemantics(
            id: const ControlId('save'),
            text: const SpokenText(label: DataText('Save')),
            behavior: const ControlBehavior(role: ControlRole.button),
            onTap: () {},
            child: const SizedBox(width: 80, height: 48),
          ),
        ),
      );
      expect(find.byKey(const Key('save')), findsOneWidget);
    });

    testWidgets('state flags appear on the node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SystematicSemantics(
            id: const ControlId('docked.tab_notes'),
            text: const SpokenText(label: DataText('Notes')),
            behavior: const ControlBehavior(
              role: ControlRole.tab,
              selected: true,
            ),
            onTap: () {},
            child: const SizedBox(width: 80, height: 48),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsIdentifier('docked.tab_notes'))
          .getSemanticsData();
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(data.role, SemanticsRole.tab);
      handle.dispose();
    });

    testWidgets('a disabled control reports disabled and has no tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const SystematicSemantics(
            id: ControlId('save'),
            text: SpokenText(label: DataText('Save')),
            behavior: ControlBehavior(
              role: ControlRole.button,
              enabled: false,
            ),
            child: SizedBox(width: 80, height: 48),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsIdentifier('save')),
        matchesSemantics(
          identifier: 'save',
          label: 'Save',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('hint and value are exposed', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const SystematicSemantics(
            id: ControlId('volume'),
            text: SpokenText(
                label: DataText('Volume'),
                hint: DataText('Drag'),
                value: DataText('70%')),
            behavior: ControlBehavior(role: ControlRole.none),
            child: SizedBox(width: 80, height: 48),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsIdentifier('volume'))
          .getSemanticsData();
      expect(data.label, 'Volume');
      expect(data.hint, 'Drag');
      expect(data.value, '70%');
      handle.dispose();
    });

    testWidgets(
        'a wrapped TextField is named once and keeps its actions on '
        'the identifier node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 240,
            child: SystematicSemantics(
              id: ControlId('name_field'),
              text: SpokenText(label: DataText('Name')),
              behavior: ControlBehavior(role: ControlRole.textField),
              child: TextField(
                decoration: InputDecoration(labelText: 'Name'),
              ),
            ),
          ),
        ),
      );
      var data = tester
          .getSemantics(find.bySemanticsIdentifier('name_field'))
          .getSemanticsData();
      expect(data.label, 'Name', reason: 'named once, not "Name Name"');
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.hasAction(SemanticsAction.focus), isTrue);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      data = tester
          .getSemantics(find.bySemanticsIdentifier('name_field'))
          .getSemanticsData();
      expect(
        data.hasAction(SemanticsAction.setText),
        isTrue,
        reason:
            'once focused, the node carrying the identifier must also carry '
            'setText, so a driver that finds by identifier can type',
      );
      handle.dispose();
    });

    testWidgets('with no text, the control is named once by its own content', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SystematicSemantics(
            id: const ControlId('save'),
            behavior: const ControlBehavior(role: ControlRole.button),
            onTap: () {},
            child: const Text('Save'),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsIdentifier('save'))
          .getSemanticsData();
      expect(data.label, 'Save');
      expect(data.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('text plus an excluded visible label is read once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SystematicSemantics(
            id: const ControlId('close'),
            text: const SpokenText(label: DataText('Close tab')),
            behavior: const ControlBehavior(role: ControlRole.button),
            onTap: () {},
            child: const ExcludeSemantics(child: Text('x')),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsIdentifier('close'))
          .getSemanticsData();
      expect(data.label, 'Close tab');
      handle.dispose();
    });

    testWidgets('a tab bar made only of tabs builds without asserting', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SystematicSemantics(
            id: const ControlId('tab_rail'),
            text: const SpokenText(label: DataText('Open tabs')),
            behavior: const ControlBehavior(role: ControlRole.tabBar),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SystematicSemantics(
                  id: const ControlId('tab_rail.a'),
                  text: const SpokenText(label: DataText('A')),
                  behavior: const ControlBehavior(
                    role: ControlRole.tab,
                    selected: true,
                  ),
                  onTap: () {},
                  child: const SizedBox(width: 60, height: 48),
                ),
                SystematicSemantics(
                  id: const ControlId('tab_rail.b'),
                  text: const SpokenText(label: DataText('B')),
                  behavior: const ControlBehavior(
                    role: ControlRole.tab,
                    selected: false,
                  ),
                  onTap: () {},
                  child: const SizedBox(width: 60, height: 48),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsIdentifier('tab_rail.a'), findsOneWidget);
      expect(find.bySemanticsIdentifier('tab_rail.b'), findsOneWidget);
      handle.dispose();
    });
  });

  group('localized labels', () {
    const saveKey = L10nKey.generated('common.save');

    testWidgets('an L10nKey is spoken in the scope\'s language',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const SystematicSemantics(
            id: ControlId('save'),
            text: SpokenText(label: saveKey, hint: DataText('h')),
            behavior: ControlBehavior(role: ControlRole.button),
            child: SizedBox(width: 80, height: 48),
          ),
          resolver: _MapResolver({'common.save': 'Guardar'}),
        ),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsIdentifier('save'))
            .getSemanticsData()
            .label,
        'Guardar',
      );
      handle.dispose();
    });

    testWidgets('changing the resolver re-speaks the label', (tester) async {
      final handle = tester.ensureSemantics();
      const control = SystematicSemantics(
        id: ControlId('save'),
        text: SpokenText(label: saveKey),
        behavior: ControlBehavior(role: ControlRole.button),
        child: SizedBox(width: 80, height: 48),
      );
      await tester.pumpWidget(
        _host(control, resolver: _MapResolver({'common.save': 'Save'})),
      );
      await tester.pumpWidget(
        _host(control, resolver: _MapResolver({'common.save': 'Guardar'})),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsIdentifier('save'))
            .getSemanticsData()
            .label,
        'Guardar',
      );
      handle.dispose();
    });

    testWidgets('building without a LabelScope fails loudly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SystematicSemantics(
            id: ControlId('save'),
            text: SpokenText(label: saveKey),
            behavior: ControlBehavior(role: ControlRole.button),
            child: SizedBox(width: 80, height: 48),
          ),
        ),
      );
      expect(tester.takeException(), isA<StateError>());
    });
  });
}
