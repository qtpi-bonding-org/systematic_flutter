import 'package:flutter_test/flutter_test.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'helpers.dart';

late CountingObserver n;

void main() {
  setUp(() {
    n = CountingObserver();
    ConnectObserver.instance = n;
  });
  tearDown(() => ConnectObserver.instance = null);

  testWidgets('every probed widget builds once at start', (t) async {
    await pumpApp(t);
    expect(n('search-panel'), 1);
    expect(n('status-view'), 1);
    expect(n('note-list:tab1'), 1);
    expect(n('tile:tab1-1'), 1);
    expect(n('tile:tab1-3'), 1);
    await unmountApp(t);
  });

  testWidgets('typing rebuilds nothing after the first character', (t) async {
    await pumpApp(t);
    await t.enterText(key('search-field'), 'a');
    await settle(t);
    final before = [
      n('search-panel'),
      n('status-view'),
      n('note-list:tab1'),
      n('tile:tab1-1'),
    ];
    await t.enterText(key('search-field'), 'ab');
    await settle(t);
    await t.enterText(key('search-field'), 'abc');
    await settle(t);
    await t.enterText(key('search-field'), 'abcd');
    await settle(t);
    expect([
      n('search-panel'),
      n('status-view'),
      n('note-list:tab1'),
      n('tile:tab1-1'),
    ], before);
    expect(session(t).search.state.query, 'abcd');
    await unmountApp(t);
  });

  testWidgets('one status tick rebuilds only the status view', (t) async {
    await pumpApp(t);
    final panel = n('search-panel');
    final list = n('note-list:tab1');
    final tile = n('tile:tab1-1');
    final status = n('status-view');
    await t.pump(const Duration(seconds: 1));
    await settle(t);
    expect(n('status-view'), status + 1);
    expect(n('search-panel'), panel);
    expect(n('note-list:tab1'), list);
    expect(n('tile:tab1-1'), tile);
    await t.pump(const Duration(seconds: 1));
    await settle(t);
    expect(n('status-view'), status + 2);
    await unmountApp(t);
  });

  testWidgets('renaming one note rebuilds only that tile', (t) async {
    await pumpApp(t);
    final t1 = n('tile:tab1-1');
    final t2 = n('tile:tab1-2');
    final t3 = n('tile:tab1-3');
    final list = n('note-list:tab1');
    final panel = n('search-panel');
    await notes(t, 'tab1').rename('tab1-2', 'New name');
    await settle(t);
    expect(n('tile:tab1-2'), t2 + 1);
    expect(n('tile:tab1-1'), t1);
    expect(n('tile:tab1-3'), t3);
    expect(n('note-list:tab1'), list);
    expect(n('search-panel'), panel);
    await unmountApp(t);
  });

  testWidgets('deleting a note rebuilds the list but not the search panel',
      (t) async {
    await pumpApp(t);
    final list = n('note-list:tab1');
    final panel = n('search-panel');
    final status = n('status-view');
    await notes(t, 'tab1').delete('tab1-2');
    await settle(t);
    expect(n('note-list:tab1'), list + 1);
    expect(n('search-panel'), panel);
    expect(n('status-view'), status);
    expect(find.text('A tab1 note 2'), findsNothing);
    await unmountApp(t);
  });

  testWidgets('selecting a note rebuilds only the affected tiles', (t) async {
    await pumpApp(t);
    final list = n('note-list:tab1');
    final t3 = n('tile:tab1-3');
    await notes(t, 'tab1').select('tab1-1');
    await settle(t);
    expect(n('tile:tab1-1'), 2);
    expect(n('tile:tab1-3'), t3);
    expect(n('note-list:tab1'), list);
    await unmountApp(t);
  });
}
