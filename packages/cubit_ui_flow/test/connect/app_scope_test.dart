import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class Notifier extends ChangeNotifier {
  Notifier(this.log);
  final List<String> log;
  @override
  void dispose() {
    log.add('notifier');
    super.dispose();
  }
}

class LoggedCubit extends Cubit<int> {
  LoggedCubit(this.log) : super(0);
  final List<String> log;
  @override
  Future<void> close() {
    log.add('cubit');
    return super.close();
  }
}

class TestScope extends AppScope {
  TestScope(this.log) {
    cubit = own(LoggedCubit(log));
    notifier = own(Notifier(log));
  }
  final List<String> log;
  late final LoggedCubit cubit;
  late final Notifier notifier;
  int disposeCalls = 0;
  @override
  void dispose() {
    disposeCalls++;
    super.dispose();
  }
}

class OtherScope extends AppScope {}

void main() {
  test('own disposes in reverse order and sets isDisposed', () {
    final log = <String>[];
    final s = TestScope(log);
    expect(s.isDisposed, isFalse);
    expect(s.cubit.isClosed, isFalse);
    s.dispose();
    expect(s.isDisposed, isTrue);
    expect(s.cubit.isClosed, isTrue);
    expect(log, ['notifier', 'cubit']);
  });

  test('own returns the value', () {
    final s = OtherScope();
    final n = ChangeNotifier();
    expect(identical(s.own(n), n), isTrue);
    s.dispose();
  });

  testWidgets('ScopeProvider creates once across parent rebuilds', (t) async {
    var creates = 0;
    final log = <String>[];
    late StateSetter set;
    var n = 0;
    await t.pumpWidget(StatefulBuilder(builder: (c, s) {
      set = s;
      return ScopeProvider<TestScope>(
        create: () {
          creates++;
          return TestScope(log);
        },
        child: Text('$n', textDirection: TextDirection.ltr),
      );
    }));
    set(() => n++);
    await t.pump();
    set(() => n++);
    await t.pump();
    expect(creates, 1);
  });

  testWidgets('ScopeProvider disposes on removal and of() finds it', (t) async {
    final log = <String>[];
    late TestScope found;
    await t.pumpWidget(ScopeProvider<TestScope>(
      create: () => TestScope(log),
      child: Builder(builder: (c) {
        found = ScopeProvider.of<TestScope>(c);
        expect(ScopeProvider.maybeOf<OtherScope>(c), isNull);
        return const SizedBox();
      }),
    ));
    expect(found.isDisposed, isFalse);
    await t.pumpWidget(const SizedBox());
    expect(found.isDisposed, isTrue);
    expect(found.disposeCalls, 1);
  });

  testWidgets('of() throws StateError when missing', (t) async {
    await t.pumpWidget(Builder(builder: (c) {
      expect(() => ScopeProvider.of<TestScope>(c), throwsStateError);
      return const SizedBox();
    }));
  });

  testWidgets('ScopeProvider.value does not dispose', (t) async {
    final s = TestScope(<String>[]);
    await t.pumpWidget(ScopeProvider<TestScope>.value(
      scope: s,
      child: Builder(builder: (c) {
        expect(ScopeProvider.of<TestScope>(c), same(s));
        return const SizedBox();
      }),
    ));
    await t.pumpWidget(const SizedBox());
    expect(s.isDisposed, isFalse);
    s.dispose();
  });
}
