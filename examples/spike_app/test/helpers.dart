import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:flutter_error_privserver/testing.dart';
import 'package:spike_app/data/in_memory_notes_source.dart';
import 'package:spike_app/notes/notes_source.dart';
import 'package:spike_app/infrastructure/error_capture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_app/app.dart';
import 'package:spike_app/notes/notes_cubit.dart';
import 'package:spike_app/scopes.dart';
import 'package:spike_app/views/home_view.dart';

Future<void> pumpApp(
  WidgetTester t, {
  String initialLocation = '/',
  NotesSource? notesSource,
}) async {
  t.view.physicalSize = const Size(1400, 1000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(SpikeApp(
    initialLocation: initialLocation,
    notesSource: notesSource ?? InMemoryNotesSource(),
  ));
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

/// Counts Connect builder runs per `debugLabel`.
class CountingObserver extends ConnectObserver {
  final Map<String, int> counts = {};

  @override
  void onBuild(String? debugLabel) {
    if (debugLabel == null) return;
    counts[debugLabel] = (counts[debugLabel] ?? 0) + 1;
  }

  int call(String label) => counts[label] ?? 0;
}

/// Holds every load until the test completes it.
class GatedNotesSource implements NotesSource {
  final List<Completer<List<Note>>> pending = [];

  @override
  Future<List<Note>> load(String workspaceId, String tabId) {
    final c = Completer<List<Note>>();
    pending.add(c);
    return c.future;
  }
}

/// Throws [error] while [fail] is true, then serves the seed notes.
class FlakyNotesSource implements NotesSource {
  FlakyNotesSource(this.error);

  final Object error;
  bool fail = true;
  int calls = 0;

  @override
  Future<List<Note>> load(String workspaceId, String tabId) async {
    calls++;
    if (fail) throw error;
    return seedNotes(workspaceId, tabId);
  }
}

/// Error capture with in-memory storage and no network, for one test.
void useErrorCapture() {
  setUp(() => configureErrorCapture(storage: InMemoryErrorBoxStorage()));
  tearDown(resetErrorCapture);
}

Future<int> capturedErrors() => ErrorPrivserver.getUnsentCount();
