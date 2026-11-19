import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_app/app.dart';
import 'package:spike_app/notes/notes_cubit.dart';
import 'package:spike_app/scopes.dart';
import 'package:spike_app/views/home_view.dart';

Future<void> pumpApp(WidgetTester t, {String initialLocation = '/'}) async {
  t.view.physicalSize = const Size(1400, 1000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(SpikeApp(initialLocation: initialLocation));
  await t.pump();
  await t.pump();
}

/// Removes the app so scope disposal cancels the status ticker.
Future<void> unmountApp(WidgetTester t) => t.pumpWidget(const SizedBox());

/// Lets stream deliveries (microtasks) and the resulting rebuild settle.
Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump();
}

SessionScope session(WidgetTester t) =>
    ScopeProvider.of<SessionScope>(t.element(find.byType(HomeView)));

WorkspaceScope workspace(WidgetTester t) =>
    ScopeProvider.of<WorkspaceScope>(t.element(find.byType(HomeView)));

NotesCubit notes(WidgetTester t, String tabId) =>
    workspace(t).notesFor(tabId);

Finder key(String k) => find.byKey(ValueKey(k));
