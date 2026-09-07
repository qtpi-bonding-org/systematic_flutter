# nav_snapshot Step 1 (library + tests) Implementation Plan — revision 2

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `nav_snapshot` package — parts that are always readable, refresh themselves, retry on policy, and notify on change — plus the binding that re-derives a route decision when an input changes. No consumer apps migrated.

**Architecture:** A `SnapshotPart<T>` is fed either by **pull** (`load:`, lazy + cached + retried) or **push** (`.observed`, stream-fed, never `Loading`). Reads inside `decide()` register as dependencies, so a part the policy never reaches is never loaded. `NavigationBinding` runs the policy, subscribes to exactly the parts read, and re-runs on change — it never captures a value and acts on it later.

**Tech Stack:** Dart/Flutter package, `flutter_lints`, `go_router` (adapter only), `flutter_test`. Flutter 3.47 beta / Dart SDK `>=3.0.0 <4.0.0`.

**Spec:** `docs/2026-09-07-nav-snapshot-library-design.md` (revision 2, same directory)
**Also read:** `docs/2026-09-07-pocketcoder-decide-paper-exercise.md` — why the API has the shape it does.

## Global Constraints

- Package name `nav_snapshot`; repo `/Users/aicoder/Documents/my-libs/flutter_nav_snapshot`.
- `lib/src/contracts/` and `lib/src/impl/` MUST import only `dart:async`. No `package:flutter/*`, no `package:go_router/*`. Task 11 enforces this.
- Only `lib/src/adapters/` may import Flutter or go_router.
- No `!` force-unwrap anywhere. Use `?.`, `??`, a local variable, or an early return.
- No code generation. Hand-written sealed classes.
- Every public type and member carries a doc comment.
- Commits follow the sibling `flutter_cubit_ui_flow` convention: `feat:`, `fix:`, `test(area):`, `chore:` — lowercase, imperative.
- Run tests with `flutter test` from the package root.

## Revision 2 changes (from the Opus review + paper exercise)

| Ref | Change | Tasks |
|---|---|---|
| B1 | Sync pull loader settles synchronously — `await` on a non-Future still suspends | 5 |
| B2 | `SnapshotPart` owns an epoch; `invalidate()` cancels in-flight loads and backoff chains | 5, 6 |
| B3 | `attempts`/`exhausted` on the `PartState` **base**, so an exhausted value retry is observable | 2 |
| B4 | Binding coalesces re-runs onto a microtask instead of recursing | 9 |
| B5/F1 | `SnapshotPart.observed` — push inputs, never `Loading` | 7 (new task) |
| B6 | `NavigationPolicy.onNavigated(TRoute)`, called only on real navigation | 8, 9 |
| S2 | Binding compares against the route it last commanded, not only `target.current` | 9 |
| S3 | `decide()` documented and tested as synchronous-only | 8, 11 |
| S5 | `go_router` bound widened to `<18.0.0` | 1 |
| F9 | `cacheKey:` self-invalidates a pull part when its key changes | 5 |
| minor | `SnapshotPart` moves to `contracts/` so `contracts/` never imports `impl/` | 5 |
| minor | `meta` dependency dropped (unused); `NavSnapshotLibraryMarker` dropped after Task 2 | 1, 2 |

## Declared deviations from the spec

1. **Union members are prefixed** — `PartLoading`/`PartReady`/`PartFailed`, `RouteStay`/`RouteWait`/`RouteGo`. Bare `Loading`/`Go` would collide with consumer types across four apps.
2. **Seeding constructors** `SnapshotPart.ready/.loading/.failed` exist for table tests; the spec does not list them.
3. **`peek()`** returns the state without registering a dependency or starting a load.
4. **`PartState` gains** `isLoading`/`isReady`/`isFailed`/`isSettled`/`valueOrNull` convenience getters.
5. **`SnapshotPart` gains** `addListener`/`removeListener`/`dispose` — the binding needs them.
6. **`EvaluationContext` is exported** from the public barrel despite living in `impl/`, because policy tests need it.
7. **A redirect-based `IRouteTarget` is out of scope.** Imperative `GoRouterTarget` only.

---

### Task 1: Package scaffold

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `lib/nav_snapshot.dart`
- Test: `test/library_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: the package, importable as `package:nav_snapshot/nav_snapshot.dart`; `class NavSnapshotLibraryMarker` with `bool get isReady` (temporary, deleted in Task 2).

- [ ] **Step 1: Create the package files**

`pubspec.yaml`:
```yaml
name: nav_snapshot
description: Navigation state snapshots with lazy pull parts, stream-fed push parts, per-part invalidation, retry, and automatic route re-decision.
version: 0.1.0
homepage: https://github.com/quanitya/flutter_nav_snapshot
repository: https://github.com/quanitya/flutter_nav_snapshot

topics:
  - flutter
  - navigation
  - routing
  - go-router
  - state

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter
  go_router: '>=13.0.0 <18.0.0'

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

`analysis_options.yaml`:
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - avoid_empty_else
    - avoid_print
    - prefer_const_constructors
    - prefer_final_fields

analyzer:
  exclude:
    - build/**
```

`.gitignore`:
```
.dart_tool/
build/
pubspec.lock
```

`lib/nav_snapshot.dart`:
```dart
/// Navigation state snapshots with lazy pull parts and stream-fed push parts.
library nav_snapshot;
```

- [ ] **Step 2: Write the failing test**

`test/library_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('package resolves and exports its library', () {
    expect(const NavSnapshotLibraryMarker().isReady, isTrue);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd /Users/aicoder/Documents/my-libs/flutter_nav_snapshot && flutter pub get && flutter test test/library_test.dart`
Expected: FAIL — `NavSnapshotLibraryMarker` is undefined.

- [ ] **Step 4: Write minimal implementation**

Append to `lib/nav_snapshot.dart`:
```dart
/// Proves the package resolves and its barrel is importable.
/// Deleted in Task 2 once real types are exported.
class NavSnapshotLibraryMarker {
  /// Creates the marker.
  const NavSnapshotLibraryMarker();

  /// Always true. Its purpose is that it compiles at all.
  bool get isReady => true;
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/library_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
cd /Users/aicoder/Documents/my-libs/flutter_nav_snapshot
git init
git add .
git commit -m "chore: scaffold nav_snapshot package"
```

---

### Task 2: PartState union with attempts and exhaustion

**Files:**
- Create: `lib/src/contracts/part_state.dart`
- Modify: `lib/nav_snapshot.dart` (add export, delete `NavSnapshotLibraryMarker`)
- Modify: `test/library_test.dart` (retarget at a real type)
- Test: `test/contracts/part_state_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `sealed class PartState<T>` with base fields `int attempts` (default 0) and `bool exhausted` (default false), plus getters `isLoading`, `isReady`, `isFailed`, `isSettled`, `T? valueOrNull`. Subclasses: `PartLoading<T>({int attempts})`, `PartReady<T>(T value, {int attempts, bool exhausted})`, `PartFailed<T>({required Object error, int attempts, bool exhausted})`.

Per spec revision 2 (B3): `attempts`/`exhausted` live on the base so an exhausted **value** retry — which settles as `PartReady` — is still observable.

- [ ] **Step 1: Write the failing test**

`test/contracts/part_state_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('loading is not settled and has no value', () {
    const state = PartLoading<int>();
    expect(state.isLoading, isTrue);
    expect(state.isSettled, isFalse);
    expect(state.valueOrNull, isNull);
    expect(state.attempts, 0);
    expect(state.exhausted, isFalse);
  });

  test('ready is settled and exposes its value', () {
    const state = PartReady<int>(7, attempts: 1);
    expect(state.isReady, isTrue);
    expect(state.isSettled, isTrue);
    expect(state.valueOrNull, 7);
    expect(state.attempts, 1);
  });

  test('an exhausted value retry is observable on PartReady', () {
    const state = PartReady<String>('unknown', attempts: 3, exhausted: true);
    expect(state.isReady, isTrue);
    expect(state.valueOrNull, 'unknown');
    expect(state.exhausted, isTrue,
        reason: 'the instanceUnverifiable route depends on this');
  });

  test('failed carries error, attempts, and exhaustion', () {
    const state = PartFailed<int>(error: 'boom', attempts: 3, exhausted: true);
    expect(state.isFailed, isTrue);
    expect(state.isSettled, isTrue);
    expect(state.valueOrNull, isNull);
    expect(state.error, 'boom');
    expect(state.attempts, 3);
  });

  test('a switch over the union is exhaustive without a default', () {
    String describe(PartState<int> state) => switch (state) {
          PartLoading<int>() => 'loading',
          PartReady<int>(value: final v) => 'ready:$v',
          PartFailed<int>(exhausted: final e) => 'failed:$e',
        };

    expect(describe(const PartLoading<int>()), 'loading');
    expect(describe(const PartReady<int>(1)), 'ready:1');
    expect(
      describe(const PartFailed<int>(error: 'x', attempts: 1, exhausted: false)),
      'failed:false',
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/contracts/part_state_test.dart`
Expected: FAIL — `PartLoading` is undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/contracts/part_state.dart`:
```dart
/// The resolution state of a single part.
///
/// `PartLoading` is deliberately distinct from a `PartReady` holding a falsey
/// value: "not answered yet" and "answered, and the answer is no" must never
/// collapse into one another.
///
/// [attempts] and [exhausted] live here rather than only on [PartFailed]
/// because a value-triggered retry that spends its budget settles as a
/// *successful* [PartReady] — the value is legitimate, it just could not be
/// improved on — and the policy still has to be able to tell that apart from
/// a first-try answer.
sealed class PartState<T> {
  /// Creates a part state.
  const PartState({this.attempts = 0, this.exhausted = false});

  /// How many load attempts produced this state.
  final int attempts;

  /// Whether the retry budget is spent. The policy decides what that means.
  final bool exhausted;

  /// Whether the part is still resolving.
  bool get isLoading => this is PartLoading<T>;

  /// Whether the part resolved to a value.
  bool get isReady => this is PartReady<T>;

  /// Whether the part resolved to a failure.
  bool get isFailed => this is PartFailed<T>;

  /// Whether the part has finished resolving, successfully or not.
  bool get isSettled => !isLoading;

  /// The resolved value, or null when loading or failed.
  T? get valueOrNull => switch (this) {
        PartReady<T>(value: final value) => value,
        _ => null,
      };
}

/// The part has not resolved yet.
final class PartLoading<T> extends PartState<T> {
  /// Creates a loading state.
  const PartLoading({super.attempts});
}

/// The part resolved to [value].
final class PartReady<T> extends PartState<T> {
  /// Creates a ready state holding [value].
  const PartReady(this.value, {super.attempts, super.exhausted});

  /// The resolved value.
  final T value;
}

/// The part failed to resolve.
final class PartFailed<T> extends PartState<T> {
  /// Creates a failed state.
  const PartFailed({
    required this.error,
    super.attempts,
    super.exhausted,
  });

  /// The error from the last attempt.
  final Object error;
}
```

Replace `lib/nav_snapshot.dart` entirely:
```dart
/// Navigation state snapshots with lazy pull parts and stream-fed push parts.
library nav_snapshot;

export 'src/contracts/part_state.dart';
```

Replace `test/library_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('package resolves and exports its library', () {
    expect(const PartLoading<int>().isLoading, isTrue);
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/contracts/part_state_test.dart test/library_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/ test/
git commit -m "feat: add PartState union with observable retry exhaustion"
```

---

### Task 3: RetryConfig

**Files:**
- Create: `lib/src/contracts/retry_config.dart`
- Modify: `lib/nav_snapshot.dart`
- Test: `test/contracts/retry_config_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `enum Backoff { fixed, exponential }`; `class RetryConfig<T>` with `maxAttempts` (int, default 1), `delay` (Duration, default zero), `backoff` (default `Backoff.fixed`), `retryOnError` (bool, default true), `retryOnValue` (`bool Function(T)?`); methods `Duration delayForAttempt(int attempt)` (1-based) and `bool shouldRetryValue(T value)`.

- [ ] **Step 1: Write the failing test**

`test/contracts/retry_config_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('defaults to a single attempt with no delay', () {
    const config = RetryConfig<int>();
    expect(config.maxAttempts, 1);
    expect(config.delay, Duration.zero);
    expect(config.retryOnError, isTrue);
    expect(config.retryOnValue, isNull);
  });

  test('fixed backoff returns the same delay for every attempt', () {
    const config = RetryConfig<int>(maxAttempts: 3, delay: Duration(seconds: 2));
    expect(config.delayForAttempt(1), const Duration(seconds: 2));
    expect(config.delayForAttempt(3), const Duration(seconds: 2));
  });

  test('exponential backoff doubles per attempt', () {
    const config = RetryConfig<int>(
      maxAttempts: 4,
      delay: Duration(seconds: 1),
      backoff: Backoff.exponential,
    );
    expect(config.delayForAttempt(1), const Duration(seconds: 1));
    expect(config.delayForAttempt(2), const Duration(seconds: 2));
    expect(config.delayForAttempt(3), const Duration(seconds: 4));
  });

  test('shouldRetryValue is false when no predicate is given', () {
    const config = RetryConfig<int>(maxAttempts: 3);
    expect(config.shouldRetryValue(1), isFalse);
  });

  test('shouldRetryValue consults the predicate', () {
    final config = RetryConfig<int>(
      maxAttempts: 3,
      retryOnValue: (value) => value == 0,
    );
    expect(config.shouldRetryValue(0), isTrue);
    expect(config.shouldRetryValue(1), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/contracts/retry_config_test.dart`
Expected: FAIL — `RetryConfig` is undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/contracts/retry_config.dart`:
```dart
/// How the delay between retry attempts grows.
enum Backoff {
  /// Every attempt waits [RetryConfig.delay].
  fixed,

  /// Attempt N waits `delay * 2^(N-1)`.
  exponential,
}

/// When and how often a pull part retries.
///
/// A retry can be triggered by a thrown error *or* by a successfully returned
/// value. The value case is not hypothetical: a provider check that returns a
/// definite "I don't know" is a successful call worth asking again.
class RetryConfig<T> {
  /// Creates a retry configuration.
  const RetryConfig({
    this.maxAttempts = 1,
    this.delay = Duration.zero,
    this.backoff = Backoff.fixed,
    this.retryOnError = true,
    this.retryOnValue,
  });

  /// Total attempts, including the first. 1 means no retry.
  final int maxAttempts;

  /// Base delay between attempts.
  final Duration delay;

  /// How [delay] grows across attempts.
  final Backoff backoff;

  /// Whether a thrown error triggers a retry.
  final bool retryOnError;

  /// Whether a successfully returned value triggers a retry.
  final bool Function(T value)? retryOnValue;

  /// The delay before the given 1-based [attempt].
  Duration delayForAttempt(int attempt) {
    if (attempt <= 1 || backoff == Backoff.fixed) return delay;
    return delay * (1 << (attempt - 1));
  }

  /// Whether [value] should be retried rather than accepted.
  bool shouldRetryValue(T value) => retryOnValue?.call(value) ?? false;
}
```

Add to `lib/nav_snapshot.dart`:
```dart
export 'src/contracts/retry_config.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/contracts/retry_config_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/src/contracts/retry_config.dart lib/nav_snapshot.dart test/contracts/retry_config_test.dart
git commit -m "feat: add RetryConfig with value-triggered retry"
```

---

### Task 4: EvaluationContext (dependency tracking)

**Files:**
- Create: `lib/src/impl/evaluation_context.dart`
- Modify: `lib/nav_snapshot.dart`
- Test: `test/impl/evaluation_context_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `class EvaluationContext` with `Set<Object> get reads`, `void recordRead(Object part)`, `static EvaluationContext? get current`, `static R track<R>(EvaluationContext context, R Function() body)`.

Tracking is ambient so `decide()` bodies read as plain code (`auth.read()`), not plumbing (`auth.read(ctx)`). The cost is that it only works synchronously — enforced by `decide()`'s signature, documented in Task 8, and tested here.

- [ ] **Step 1: Write the failing test**

`test/impl/evaluation_context_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('no context is current outside track', () {
    expect(EvaluationContext.current, isNull);
  });

  test('track exposes the context and records reads', () {
    final context = EvaluationContext();
    final marker = Object();

    final result = EvaluationContext.track(context, () {
      EvaluationContext.current?.recordRead(marker);
      return 42;
    });

    expect(result, 42);
    expect(context.reads, contains(marker));
    expect(EvaluationContext.current, isNull);
  });

  test('track restores the previous context even when body throws', () {
    final outer = EvaluationContext();
    final inner = EvaluationContext();

    EvaluationContext.track(outer, () {
      expect(
        () => EvaluationContext.track(inner, () => throw StateError('x')),
        throwsStateError,
      );
      expect(EvaluationContext.current, same(outer));
    });

    expect(EvaluationContext.current, isNull);
  });

  test('tracking does not survive an async gap', () async {
    final context = EvaluationContext();
    final marker = Object();

    EvaluationContext.track(context, () {
      Future<void>.delayed(Duration.zero).then((_) {
        EvaluationContext.current?.recordRead(marker);
      });
      return null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      context.reads,
      isNot(contains(marker)),
      reason: 'this is why NavigationPolicy.decide() must be synchronous',
    );
  });

  test('a fresh context starts with no reads', () {
    expect(EvaluationContext().reads, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/impl/evaluation_context_test.dart`
Expected: FAIL — `EvaluationContext` is undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/impl/evaluation_context.dart`:
```dart
/// Records which parts were read during one policy evaluation.
///
/// The binding recomputes the dependency set on every evaluation rather than
/// accumulating it, so a part that stops being reached also stops being
/// subscribed to.
///
/// Ambient, and therefore synchronous-only: [current] is restored when
/// [track]'s body returns, which for an `async` body is its first `await`.
/// `NavigationPolicy.decide()` must not be async.
class EvaluationContext {
  static EvaluationContext? _current;

  final Set<Object> _reads = <Object>{};

  /// The parts read during this evaluation.
  Set<Object> get reads => Set<Object>.unmodifiable(_reads);

  /// The evaluation currently in progress, or null outside one.
  static EvaluationContext? get current => _current;

  /// Records that [part] was read.
  void recordRead(Object part) => _reads.add(part);

  /// Runs [body] with [context] installed as [current].
  static R track<R>(EvaluationContext context, R Function() body) {
    final previous = _current;
    _current = context;
    try {
      return body();
    } finally {
      _current = previous;
    }
  }
}
```

Add to `lib/nav_snapshot.dart`:
```dart
export 'src/impl/evaluation_context.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/impl/evaluation_context_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/src/impl/evaluation_context.dart lib/nav_snapshot.dart test/impl/evaluation_context_test.dart
git commit -m "feat: add EvaluationContext dependency tracking"
```

---

### Task 5: SnapshotPart — pull, sync fast path, epoch guard, cacheKey

**Files:**
- Create: `lib/src/contracts/snapshot_part.dart`
- Modify: `lib/nav_snapshot.dart`
- Test: `test/contracts/snapshot_part_test.dart`

**Interfaces:**
- Consumes: `PartState` (Task 2), `RetryConfig` (Task 3), `EvaluationContext` (Task 4).
- Produces: `class SnapshotPart<T>` with:
  - `SnapshotPart({required String name, required FutureOr<T> Function() load, RetryConfig<T>? retry, Object? Function()? cacheKey})`
  - `SnapshotPart.ready(String name, T value)`, `.loading(String name)`, `.failed(String name, {required Object error, int attempts, bool exhausted})`
  - `PartState<T> read()`, `PartState<T> peek()`, `void invalidate()`, `void addListener(void Function())`, `void removeListener(void Function())`, `void dispose()`, `final String name`

It lives in `contracts/` because it is public surface that `NavigationPolicy` refers to; putting it in `impl/` would force `contracts/` to import `impl/`. Retry behavior arrives in Task 6; the push constructor in Task 7.

- [ ] **Step 1: Write the failing test**

`test/contracts/snapshot_part_test.dart`:
```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('peek neither loads nor registers a dependency', () async {
    var calls = 0;
    final part = SnapshotPart<int>(name: 'p', load: () async {
      calls++;
      return 1;
    });

    expect(part.peek(), isA<PartLoading<int>>());
    await Future<void>.delayed(Duration.zero);
    expect(calls, 0);
  });

  test('a synchronous loader settles synchronously', () {
    final part = SnapshotPart<int>(name: 'p', load: () => 9);
    final state = part.read();
    expect(state, isA<PartReady<int>>(),
        reason: 'a known fact must not force a spurious Wait');
    expect(state.valueOrNull, 9);
  });

  test('an async loader settles after a microtask and caches', () async {
    var calls = 0;
    final part = SnapshotPart<int>(name: 'p', load: () async {
      calls++;
      return 1;
    });

    expect(part.read(), isA<PartLoading<int>>());
    await Future<void>.delayed(Duration.zero);
    expect(part.read().valueOrNull, 1);
    expect(part.read().valueOrNull, 1);
    expect(calls, 1);
  });

  test('concurrent reads share one in-flight load', () async {
    var calls = 0;
    final completer = Completer<int>();
    final part = SnapshotPart<int>(name: 'p', load: () {
      calls++;
      return completer.future;
    });

    part.read();
    part.read();
    part.read();
    completer.complete(5);
    await Future<void>.delayed(Duration.zero);

    expect(calls, 1);
    expect(part.read().valueOrNull, 5);
  });

  test('invalidate drops the answer and reloads on next read', () async {
    var calls = 0;
    final part = SnapshotPart<int>(name: 'p', load: () async => ++calls);

    part.read();
    await Future<void>.delayed(Duration.zero);
    expect(part.read().valueOrNull, 1);

    part.invalidate();
    expect(part.peek(), isA<PartLoading<int>>());
    part.read();
    await Future<void>.delayed(Duration.zero);
    expect(part.read().valueOrNull, 2);
  });

  test('invalidate cancels an in-flight load rather than letting it land',
      () async {
    final first = Completer<int>();
    var calls = 0;
    final part = SnapshotPart<int>(name: 'p', load: () {
      calls++;
      return calls == 1 ? first.future : Future<int>.value(2);
    });

    part.read();
    part.invalidate();
    first.complete(1);
    await Future<void>.delayed(Duration.zero);

    expect(part.peek(), isA<PartLoading<int>>(),
        reason: 'a superseded load must not resurrect the old answer');
  });

  test('a superseded load never overwrites a newer one', () async {
    final first = Completer<int>();
    final second = Completer<int>();
    var calls = 0;
    final part = SnapshotPart<int>(name: 'p', load: () {
      calls++;
      return calls == 1 ? first.future : second.future;
    });

    part.read();
    part.invalidate();
    part.read();

    second.complete(2);
    await Future<void>.delayed(Duration.zero);
    first.complete(1);
    await Future<void>.delayed(Duration.zero);

    expect(part.peek().valueOrNull, 2);
  });

  test('a cacheKey change self-invalidates on next read', () async {
    var key = 'a';
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async => ++calls,
      cacheKey: () => key,
    );

    part.read();
    await Future<void>.delayed(Duration.zero);
    expect(part.read().valueOrNull, 1);

    key = 'b';
    expect(part.read(), isA<PartLoading<int>>());
    await Future<void>.delayed(Duration.zero);
    expect(part.read().valueOrNull, 2);
  });

  test('invalidating one part leaves others untouched', () async {
    final a = SnapshotPart<int>(name: 'a', load: () => 1);
    final b = SnapshotPart<int>(name: 'b', load: () => 2);
    a.read();
    b.read();

    a.invalidate();

    expect(a.peek(), isA<PartLoading<int>>());
    expect(b.peek().valueOrNull, 2);
  });

  test('a thrown error becomes PartFailed', () async {
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async => throw StateError('nope'),
    );

    part.read();
    await Future<void>.delayed(Duration.zero);
    final state = part.read();
    expect(state, isA<PartFailed<int>>());
    expect(state.attempts, 1);
    expect(state.exhausted, isTrue);
  });

  test('listeners fire when the part settles and on invalidate', () async {
    var notifications = 0;
    final part = SnapshotPart<int>(name: 'p', load: () async => 1);
    part.addListener(() => notifications++);

    part.read();
    await Future<void>.delayed(Duration.zero);
    expect(notifications, 1);

    part.invalidate();
    expect(notifications, 2);
  });

  test('read registers a dependency, peek does not', () {
    final part = SnapshotPart<int>(name: 'p', load: () => 1);
    final context = EvaluationContext();

    EvaluationContext.track(context, () {
      part.peek();
      expect(context.reads, isEmpty);
      part.read();
    });

    expect(context.reads, contains(part));
  });

  test('seeding constructors produce fixed states without loading', () {
    expect(SnapshotPart<int>.ready('a', 3).peek().valueOrNull, 3);
    expect(SnapshotPart<int>.loading('b').peek(), isA<PartLoading<int>>());

    final failed = SnapshotPart<int>.failed('c', error: 'x').peek();
    expect(failed, isA<PartFailed<int>>());
    expect(failed.exhausted, isTrue);
  });

  test('dispose removes listeners', () async {
    var notifications = 0;
    final part = SnapshotPart<int>(name: 'p', load: () async => 1);
    part.addListener(() => notifications++);

    part.dispose();
    part.read();
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/contracts/snapshot_part_test.dart`
Expected: FAIL — `SnapshotPart` is undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/contracts/snapshot_part.dart`:
```dart
import 'dart:async';

import '../impl/evaluation_context.dart';
import 'part_state.dart';
import 'retry_config.dart';

/// One independently-refreshable fact behind a routing decision.
///
/// Loading is lazy: a part no policy branch reads is never fetched. That is
/// what lets a policy skip an expensive call simply by not reaching the line
/// that reads it.
class SnapshotPart<T> {
  /// Creates a pull part, loaded via [load] on first read and cached.
  ///
  /// When [cacheKey] is supplied it is evaluated on every [read]; a change
  /// invalidates the cached answer.
  SnapshotPart({
    required this.name,
    required FutureOr<T> Function() load,
    RetryConfig<T>? retry,
    Object? Function()? cacheKey,
  })  : _load = load,
        _retry = retry ?? RetryConfig<T>(),
        _cacheKey = cacheKey,
        _observedRead = null,
        _state = PartLoading<T>(),
        _settled = false;

  /// Creates a part fixed at [value]. For tests and seeded policies.
  SnapshotPart.ready(this.name, T value)
      : _load = (() => value),
        _retry = RetryConfig<T>(),
        _cacheKey = null,
        _observedRead = null,
        _state = PartReady<T>(value, attempts: 1),
        _settled = true;

  /// Creates a part fixed in the loading state. For tests.
  SnapshotPart.loading(this.name)
      : _load = (() => throw StateError('seeded loading part never loads')),
        _retry = RetryConfig<T>(),
        _cacheKey = null,
        _observedRead = null,
        _state = PartLoading<T>(),
        _settled = true;

  /// Creates a part fixed in the failed state. For tests.
  SnapshotPart.failed(
    this.name, {
    required Object error,
    int attempts = 1,
    bool exhausted = true,
  })  : _load = (() => throw StateError('seeded failed part never loads')),
        _retry = RetryConfig<T>(),
        _cacheKey = null,
        _observedRead = null,
        _state = PartFailed<T>(
          error: error,
          attempts: attempts,
          exhausted: exhausted,
        ),
        _settled = true;

  /// A stable identifier, used in logs and debugging.
  final String name;

  final FutureOr<T> Function() _load;
  final RetryConfig<T> _retry;
  final Object? Function()? _cacheKey;
  final T Function()? _observedRead;
  final List<void Function()> _listeners = <void Function()>[];

  PartState<T> _state;
  bool _settled;
  Object? _lastCacheKey;

  /// Guards against a superseded load landing after an [invalidate].
  ///
  /// This is the generation counter that a consumer would otherwise hand-roll
  /// once per app; it is written here once instead.
  int _epoch = 0;
  Future<void>? _inFlight;

  /// The current state, registering this part as a dependency of the
  /// evaluation in progress and starting a load if none has run.
  PartState<T> read() {
    EvaluationContext.current?.recordRead(this);
    _checkCacheKey();
    _ensureLoading();
    return _state;
  }

  /// The current state, without registering a dependency or starting a load.
  PartState<T> peek() => _state;

  /// Drops the cached answer and cancels any load in flight.
  void invalidate() {
    _epoch++;
    _inFlight = null;
    _settled = false;
    _state = PartLoading<T>();
    _notify();
  }

  /// Registers [listener], called whenever the state changes.
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Removes a previously added [listener].
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Drops all listeners.
  void dispose() => _listeners.clear();

  void _checkCacheKey() {
    final keyFn = _cacheKey;
    if (keyFn == null) return;
    final key = keyFn();
    if (_settled && key != _lastCacheKey) invalidate();
    _lastCacheKey = key;
  }

  void _ensureLoading() {
    if (_settled || _inFlight != null) return;
    _attempt(1);
  }

  void _attempt(int attempt) {
    final epoch = _epoch;
    try {
      final result = _load();
      if (result is Future<T>) {
        _inFlight = _awaitValue(result, attempt, epoch);
        return;
      }
      _settleValue(result, attempt, epoch);
    } on Object catch (error) {
      _settleError(error, attempt, epoch);
    }
  }

  Future<void> _awaitValue(Future<T> future, int attempt, int epoch) async {
    try {
      final value = await future;
      if (epoch != _epoch) return;
      _settleValue(value, attempt, epoch);
    } on Object catch (error) {
      if (epoch != _epoch) return;
      _settleError(error, attempt, epoch);
    }
  }

  void _settleValue(T value, int attempt, int epoch) {
    _finish(PartReady<T>(value, attempts: attempt), epoch);
  }

  void _settleError(Object error, int attempt, int epoch) {
    _finish(
      PartFailed<T>(error: error, attempts: attempt, exhausted: true),
      epoch,
    );
  }

  void _finish(PartState<T> state, int epoch) {
    if (epoch != _epoch) return;
    _state = state;
    _settled = true;
    _inFlight = null;
    _notify();
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}
```

Add to `lib/nav_snapshot.dart`:
```dart
export 'src/contracts/snapshot_part.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/contracts/snapshot_part_test.dart`
Expected: PASS (14 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/src/contracts/snapshot_part.dart lib/nav_snapshot.dart test/contracts/snapshot_part_test.dart
git commit -m "feat: add SnapshotPart with lazy load, epoch guard, and cacheKey"
```

---

### Task 6: SnapshotPart retry

**Files:**
- Modify: `lib/src/contracts/snapshot_part.dart`
- Test: `test/contracts/snapshot_part_retry_test.dart`

**Interfaces:**
- Consumes: `SnapshotPart` (Task 5), `RetryConfig` (Task 3).
- Produces: no new public names. `SnapshotPart` honours `retry`. An exhausted **value** retry settles as `PartReady(lastValue, attempts: n, exhausted: true)`. An exhausted **error** retry settles as `PartFailed(..., exhausted: true)`. `invalidate()` during a backoff wait cancels the chain.

- [ ] **Step 1: Write the failing test**

`test/contracts/snapshot_part_retry_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('retries a thrown error up to maxAttempts', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(maxAttempts: 3),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(calls, 3);
    expect(part.peek(), isA<PartFailed<int>>());
    expect(part.peek().attempts, 3);
    expect(part.peek().exhausted, isTrue);
  });

  test('stops retrying as soon as an attempt succeeds', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        if (calls < 2) throw StateError('boom');
        return 7;
      },
      retry: const RetryConfig<int>(maxAttempts: 3),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(part.peek().valueOrNull, 7);
    expect(calls, 2);
  });

  test('does not retry an error when retryOnError is false', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(maxAttempts: 3, retryOnError: false),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(calls, 1);
    expect(part.peek().attempts, 1);
  });

  test('retries a value the predicate rejects', () async {
    var calls = 0;
    final part = SnapshotPart<String>(
      name: 'existence',
      load: () async {
        calls++;
        return calls < 3 ? 'unknown' : 'exists';
      },
      retry: RetryConfig<String>(
        maxAttempts: 5,
        retryOnValue: (value) => value == 'unknown',
      ),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(part.peek().valueOrNull, 'exists');
    expect(part.peek().exhausted, isFalse);
    expect(calls, 3);
  });

  test('an exhausted value retry settles ready, exhausted, with the value',
      () async {
    var calls = 0;
    final part = SnapshotPart<String>(
      name: 'existence',
      load: () async {
        calls++;
        return 'unknown';
      },
      retry: RetryConfig<String>(
        maxAttempts: 3,
        retryOnValue: (value) => value == 'unknown',
      ),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(calls, 3);
    expect(part.peek(), isA<PartReady<String>>());
    expect(part.peek().valueOrNull, 'unknown');
    expect(part.peek().exhausted, isTrue,
        reason: 'the policy must be able to route to instanceUnverifiable');
    expect(part.peek().attempts, 3);
  });

  test('waits the configured delay between attempts', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(
        maxAttempts: 3,
        delay: Duration(milliseconds: 40),
      ),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, 1);

    await Future<void>.delayed(const Duration(milliseconds: 130));
    expect(calls, 3);
  });

  test('invalidate during a backoff wait cancels the chain', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(
        maxAttempts: 3,
        delay: Duration(milliseconds: 40),
      ),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(calls, 1);

    part.invalidate();
    await Future<void>.delayed(const Duration(milliseconds: 130));

    expect(calls, 1,
        reason: 'the sleeping chain must not resume after invalidate');
  });

  test('invalidate resets the attempt counter', () async {
    var calls = 0;
    final part = SnapshotPart<int>(
      name: 'p',
      load: () async {
        calls++;
        throw StateError('boom');
      },
      retry: const RetryConfig<int>(maxAttempts: 2),
    );

    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(calls, 2);

    part.invalidate();
    part.read();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(calls, 4);
    expect(part.peek().attempts, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/contracts/snapshot_part_retry_test.dart`
Expected: FAIL — only one attempt is made; `calls` is 1 where 3 is expected.

- [ ] **Step 3: Write minimal implementation**

In `lib/src/contracts/snapshot_part.dart`, replace `_settleValue` and
`_settleError`, and add `_scheduleNext`:

```dart
  void _settleValue(T value, int attempt, int epoch) {
    final wantsRetry = _retry.shouldRetryValue(value);
    if (wantsRetry && attempt < _retry.maxAttempts) {
      _scheduleNext(attempt, epoch);
      return;
    }
    _finish(
      PartReady<T>(value, attempts: attempt, exhausted: wantsRetry),
      epoch,
    );
  }

  void _settleError(Object error, int attempt, int epoch) {
    if (_retry.retryOnError && attempt < _retry.maxAttempts) {
      _scheduleNext(attempt, epoch);
      return;
    }
    _finish(
      PartFailed<T>(error: error, attempts: attempt, exhausted: true),
      epoch,
    );
  }

  void _scheduleNext(int attempt, int epoch) {
    _inFlight = Future<void>.delayed(_retry.delayForAttempt(attempt)).then((_) {
      if (epoch != _epoch) return;
      _attempt(attempt + 1);
    });
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/contracts/`
Expected: PASS (8 new + 14 from Task 5 + Tasks 2, 3)

- [ ] **Step 5: Commit**

```bash
git add lib/src/contracts/snapshot_part.dart test/contracts/snapshot_part_retry_test.dart
git commit -m "feat: honour RetryConfig in SnapshotPart"
```

---

### Task 7: SnapshotPart.observed — push inputs

**Files:**
- Modify: `lib/src/contracts/snapshot_part.dart`
- Test: `test/contracts/snapshot_part_observed_test.dart`

**Interfaces:**
- Consumes: `SnapshotPart` (Tasks 5–6).
- Produces: `SnapshotPart.observed({required String name, required T Function() read, required Stream<void> changes})`. An observed part is `PartReady` from construction, never returns to `PartLoading`, cannot fail, and ignores `RetryConfig`. `dispose()` cancels its subscription.

This is the primitive three of PocketCoder's five inputs and *all* inputs in the other three apps actually need — see the paper exercise, finding F1.

- [ ] **Step 1: Write the failing test**

`test/contracts/snapshot_part_observed_test.dart`:
```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

void main() {
  test('is ready immediately, never loading', () {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'readiness',
      read: () => 1,
      changes: changes.stream,
    );

    expect(part.peek(), isA<PartReady<int>>());
    expect(part.peek().valueOrNull, 1);
  });

  test('re-reads on stream emission without passing through loading', () async {
    var value = 1;
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'readiness',
      read: () => value,
      changes: changes.stream,
    );

    final seen = <bool>[];
    part.addListener(() => seen.add(part.peek().isLoading));

    value = 2;
    changes.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(part.peek().valueOrNull, 2);
    expect(seen, everyElement(isFalse),
        reason: 'a known value must never flash through PartLoading');
  });

  test('notifies listeners on emission', () async {
    var notifications = 0;
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'p',
      read: () => 1,
      changes: changes.stream,
    );
    part.addListener(() => notifications++);

    changes.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 1);
  });

  test('invalidate re-reads synchronously and stays ready', () {
    var value = 1;
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'p',
      read: () => value,
      changes: changes.stream,
    );

    value = 5;
    part.invalidate();

    expect(part.peek(), isA<PartReady<int>>());
    expect(part.peek().valueOrNull, 5);
  });

  test('read registers a dependency', () {
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'p',
      read: () => 1,
      changes: changes.stream,
    );
    final context = EvaluationContext();

    EvaluationContext.track(context, part.read);

    expect(context.reads, contains(part));
  });

  test('dispose cancels the subscription', () async {
    var reads = 0;
    final changes = StreamController<void>.broadcast();
    addTearDown(changes.close);

    final part = SnapshotPart<int>.observed(
      name: 'p',
      read: () {
        reads++;
        return 1;
      },
      changes: changes.stream,
    );

    final afterConstruction = reads;
    part.dispose();
    changes.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(reads, afterConstruction);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/contracts/snapshot_part_observed_test.dart`
Expected: FAIL — `SnapshotPart.observed` is not defined.

- [ ] **Step 3: Write minimal implementation**

In `lib/src/contracts/snapshot_part.dart`, add the constructor after
`SnapshotPart.failed`:

```dart
  /// Creates a push part fed by [changes], re-reading via [read] on every
  /// emission.
  ///
  /// Ready from construction and never `PartLoading` again: the value is
  /// already in memory, and routing it through a loading state would
  /// manufacture an "I don't know" for something the app does know.
  SnapshotPart.observed({
    required this.name,
    required T Function() read,
    required Stream<void> changes,
  })  : _load = read,
        _retry = RetryConfig<T>(),
        _cacheKey = null,
        _observedRead = read,
        _state = PartReady<T>(read(), attempts: 1),
        _settled = true {
    _subscription = changes.listen((_) => _refreshObserved(read));
  }
```

Add the field and helper:

```dart
  StreamSubscription<void>? _subscription;

  void _refreshObserved(T Function() read) {
    _state = PartReady<T>(read(), attempts: 1);
    _notify();
  }
```

Replace `invalidate` and `dispose`:

```dart
  /// Drops the cached answer and cancels any load in flight.
  ///
  /// An observed part re-reads its source synchronously instead — there is
  /// nothing to cancel and no loading state to enter.
  void invalidate() {
    final observedRead = _observedRead;
    if (observedRead != null) {
      _refreshObserved(observedRead);
      return;
    }
    _epoch++;
    _inFlight = null;
    _settled = false;
    _state = PartLoading<T>();
    _notify();
  }

  /// Drops all listeners and cancels any stream subscription.
  void dispose() {
    _listeners.clear();
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/contracts/`
Expected: PASS (6 new + all prior contract tests)

- [ ] **Step 5: Commit**

```bash
git add lib/src/contracts/snapshot_part.dart test/contracts/snapshot_part_observed_test.dart
git commit -m "feat: add SnapshotPart.observed for stream-fed push inputs"
```

---

### Task 8: RouteDecision, NavigationPolicy, IRouteTarget

**Files:**
- Create: `lib/src/contracts/route_decision.dart`, `lib/src/contracts/navigation_policy.dart`, `lib/src/contracts/route_target.dart`
- Modify: `lib/nav_snapshot.dart`
- Test: `test/contracts/route_decision_test.dart`, `test/contracts/navigation_policy_test.dart`

**Interfaces:**
- Consumes: `SnapshotPart` (Tasks 5–7), `PartState` (Task 2).
- Produces: `sealed class RouteDecision<TRoute>` with `RouteStay<TRoute>()`, `RouteWait<TRoute>()`, `RouteGo<TRoute>(TRoute to)`, all with value equality; `abstract class NavigationPolicy<TRoute>` with `List<SnapshotPart<Object?>> get parts`, `RouteDecision<TRoute> decide()`, and `void onNavigated(TRoute route) {}`; `abstract interface class IRouteTarget<TRoute>` with `TRoute? get current` and `void go(TRoute route)`.

- [ ] **Step 1: Write the failing test**

`test/contracts/route_decision_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

enum TestRoute { home, login }

void main() {
  test('stay and wait are distinct decisions', () {
    expect(const RouteStay<TestRoute>(), isNot(const RouteWait<TestRoute>()));
  });

  test('go carries its destination', () {
    expect(const RouteGo<TestRoute>(TestRoute.login).to, TestRoute.login);
  });

  test('a switch over the union is exhaustive without a default', () {
    String describe(RouteDecision<TestRoute> decision) => switch (decision) {
          RouteStay<TestRoute>() => 'stay',
          RouteWait<TestRoute>() => 'wait',
          RouteGo<TestRoute>(to: final route) => 'go:${route.name}',
        };

    expect(describe(const RouteStay<TestRoute>()), 'stay');
    expect(describe(const RouteWait<TestRoute>()), 'wait');
    expect(describe(const RouteGo<TestRoute>(TestRoute.home)), 'go:home');
  });

  test('equal decisions compare equal', () {
    expect(const RouteGo<TestRoute>(TestRoute.home),
        const RouteGo<TestRoute>(TestRoute.home));
    expect(const RouteGo<TestRoute>(TestRoute.home),
        isNot(const RouteGo<TestRoute>(TestRoute.login)));
    expect(const RouteStay<TestRoute>(), const RouteStay<TestRoute>());
  });
}
```

`test/contracts/navigation_policy_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

enum TestRoute { home, login, gone }

/// Shaped like a real policy: a gate, then a branch that reads a second part
/// only when the gate fails.
class TestPolicy extends NavigationPolicy<TestRoute> {
  TestPolicy({required this.signedIn, required this.exists});

  final SnapshotPart<bool> signedIn;
  final SnapshotPart<bool> exists;
  final List<TestRoute> navigated = <TestRoute>[];

  @override
  List<SnapshotPart<Object?>> get parts => [signedIn, exists];

  @override
  RouteDecision<TestRoute> decide() {
    final auth = signedIn.read();
    if (auth is! PartReady<bool>) return const RouteWait<TestRoute>();
    if (auth.value) return const RouteGo<TestRoute>(TestRoute.home);

    final existence = exists.read();
    if (existence is! PartReady<bool>) return const RouteWait<TestRoute>();
    return existence.value
        ? const RouteGo<TestRoute>(TestRoute.login)
        : const RouteGo<TestRoute>(TestRoute.gone);
  }

  @override
  void onNavigated(TestRoute route) => navigated.add(route);
}

void main() {
  test('table-driven decisions over seeded parts', () {
    final rows = <({
      String name,
      bool? auth,
      bool? exists,
      RouteDecision<TestRoute> expected
    })>[
      (name: 'auth unresolved', auth: null, exists: null, expected: const RouteWait<TestRoute>()),
      (name: 'signed in', auth: true, exists: null, expected: const RouteGo<TestRoute>(TestRoute.home)),
      (name: 'signed out, exists', auth: false, exists: true, expected: const RouteGo<TestRoute>(TestRoute.login)),
      (name: 'signed out, gone', auth: false, exists: false, expected: const RouteGo<TestRoute>(TestRoute.gone)),
      (name: 'signed out, existence unresolved', auth: false, exists: null, expected: const RouteWait<TestRoute>()),
    ];

    for (final row in rows) {
      final auth = row.auth;
      final exists = row.exists;
      final policy = TestPolicy(
        signedIn: auth == null
            ? SnapshotPart<bool>.loading('auth')
            : SnapshotPart<bool>.ready('auth', auth),
        exists: exists == null
            ? SnapshotPart<bool>.loading('exists')
            : SnapshotPart<bool>.ready('exists', exists),
      );

      expect(policy.decide(), row.expected, reason: row.name);
    }
  });

  test('a part the policy never reaches is never read', () {
    final exists = SnapshotPart<bool>.ready('exists', true);
    final policy = TestPolicy(
      signedIn: SnapshotPart<bool>.ready('auth', true),
      exists: exists,
    );

    final context = EvaluationContext();
    EvaluationContext.track(context, policy.decide);

    expect(context.reads, isNot(contains(exists)));
  });

  test('repeating an evaluation yields the same decision', () {
    final policy = TestPolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      exists: SnapshotPart<bool>.ready('exists', false),
    );

    expect(policy.decide(), policy.decide());
  });

  test('onNavigated defaults to doing nothing', () {
    final policy = _MinimalPolicy();
    expect(() => policy.onNavigated(TestRoute.home), returnsNormally);
  });
}

class _MinimalPolicy extends NavigationPolicy<TestRoute> {
  @override
  List<SnapshotPart<Object?>> get parts => const [];

  @override
  RouteDecision<TestRoute> decide() => const RouteStay<TestRoute>();
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/contracts/route_decision_test.dart test/contracts/navigation_policy_test.dart`
Expected: FAIL — `RouteStay` and `NavigationPolicy` are undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/contracts/route_decision.dart`:
```dart
/// What a policy concluded about where the user should be.
///
/// [RouteWait] and [RouteStay] are deliberately separate. "I cannot decide
/// yet" and "I decided, and the answer is to leave them alone" produce the
/// same immediate non-action but mean different things, and collapsing them
/// is how a router ends up navigating on a guess.
sealed class RouteDecision<TRoute> {
  /// Creates a decision.
  const RouteDecision();
}

/// Decided: leave the user where they are.
final class RouteStay<TRoute> extends RouteDecision<TRoute> {
  /// Creates a stay decision.
  const RouteStay();

  @override
  bool operator ==(Object other) => other is RouteStay<TRoute>;

  @override
  int get hashCode => (RouteStay<TRoute>).hashCode;
}

/// Undecided: one or more inputs have not resolved.
final class RouteWait<TRoute> extends RouteDecision<TRoute> {
  /// Creates a wait decision.
  const RouteWait();

  @override
  bool operator ==(Object other) => other is RouteWait<TRoute>;

  @override
  int get hashCode => (RouteWait<TRoute>).hashCode;
}

/// Decided: the user belongs at [to].
final class RouteGo<TRoute> extends RouteDecision<TRoute> {
  /// Creates a go decision targeting [to].
  const RouteGo(this.to);

  /// The destination.
  final TRoute to;

  @override
  bool operator ==(Object other) => other is RouteGo<TRoute> && other.to == to;

  @override
  int get hashCode => Object.hash(RouteGo<TRoute>, to);
}
```

`lib/src/contracts/navigation_policy.dart`:
```dart
import 'route_decision.dart';
import 'snapshot_part.dart';

/// The one interface a consuming app implements.
abstract class NavigationPolicy<TRoute> {
  /// Every part this policy may read.
  ///
  /// Used for lifecycle only — which parts are actually read is discovered
  /// per evaluation, so a part listed here but never read is never loaded.
  List<SnapshotPart<Object?>> get parts;

  /// Decides where the user belongs, given the parts read.
  ///
  /// MUST be synchronous. Dependency tracking is ambient and does not survive
  /// an `await`, so an async implementation would silently record only the
  /// reads before its first suspension.
  ///
  /// May read app-owned fields on the policy itself; those fields must be
  /// constructor-settable so tests can seed them.
  RouteDecision<TRoute> decide();

  /// Called after the binding actually navigated to [route].
  ///
  /// This is where cross-evaluation memory belongs — a latch recording "we
  /// have confirmed this session" or "we pushed the progress screen". Writing
  /// such state inside [decide] would set it on evaluations where nothing
  /// moved, since a `RouteGo` for the route already showing does not navigate.
  void onNavigated(TRoute route) {}
}
```

`lib/src/contracts/route_target.dart`:
```dart
/// Where a decision is applied. Implemented by a router adapter.
abstract interface class IRouteTarget<TRoute> {
  /// The route currently shown, or null when it cannot be determined.
  TRoute? get current;

  /// Navigates to [route].
  void go(TRoute route);
}
```

Add to `lib/nav_snapshot.dart`:
```dart
export 'src/contracts/route_decision.dart';
export 'src/contracts/navigation_policy.dart';
export 'src/contracts/route_target.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/contracts/`
Expected: PASS (4 + 4 new, plus all prior contract tests)

- [ ] **Step 5: Commit**

```bash
git add lib/src/contracts/ lib/nav_snapshot.dart test/contracts/
git commit -m "feat: add RouteDecision, NavigationPolicy with onNavigated, and IRouteTarget"
```

---

### Task 9: NavigationBinding

**Files:**
- Create: `lib/src/impl/navigation_binding.dart`
- Modify: `lib/nav_snapshot.dart`
- Test: `test/impl/navigation_binding_test.dart`

**Interfaces:**
- Consumes: `NavigationPolicy`, `RouteDecision`, `IRouteTarget` (Task 8), `SnapshotPart` (Tasks 5–7), `EvaluationContext` (Task 4).
- Produces: `class NavigationBinding<TRoute>` with `NavigationBinding({required NavigationPolicy<TRoute> policy, required IRouteTarget<TRoute> target})`, `void start()`, `RouteDecision<TRoute> evaluate()`, `void dispose()`, `RouteDecision<TRoute>? get lastDecision`.

Re-runs are coalesced onto a microtask (B4); the binding compares against the route it last commanded as well as `target.current` (S2); `onNavigated` fires only on real navigation (B6).

- [ ] **Step 1: Write the failing test**

`test/impl/navigation_binding_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

enum TestRoute { boot, home, login }

class RecordingTarget implements IRouteTarget<TestRoute> {
  RecordingTarget([this._current = TestRoute.boot]);

  TestRoute? _current;
  final List<TestRoute> navigations = <TestRoute>[];

  /// When true, `current` lags behind `go` — as GoRouter's does within a frame.
  bool lagging = false;

  @override
  TestRoute? get current => _current;

  @override
  void go(TestRoute route) {
    navigations.add(route);
    if (!lagging) _current = route;
  }
}

class GatePolicy extends NavigationPolicy<TestRoute> {
  GatePolicy({required this.signedIn, required this.detail});

  final SnapshotPart<bool> signedIn;
  final SnapshotPart<bool> detail;
  final List<TestRoute> navigated = <TestRoute>[];
  int decideCalls = 0;

  @override
  List<SnapshotPart<Object?>> get parts => [signedIn, detail];

  @override
  RouteDecision<TestRoute> decide() {
    decideCalls++;
    final auth = signedIn.read();
    if (auth is! PartReady<bool>) return const RouteWait<TestRoute>();
    if (!auth.value) return const RouteGo<TestRoute>(TestRoute.login);
    final extra = detail.read();
    if (extra is! PartReady<bool>) return const RouteWait<TestRoute>();
    return const RouteGo<TestRoute>(TestRoute.home);
  }

  @override
  void onNavigated(TestRoute route) => navigated.add(route);
}

class StayPolicy extends NavigationPolicy<TestRoute> {
  @override
  List<SnapshotPart<Object?>> get parts => const [];

  @override
  RouteDecision<TestRoute> decide() => const RouteStay<TestRoute>();
}

/// Invalidates a part it also reads — the pattern that overflowed the stack
/// in revision 1, and a faithful port of boot_routing_decider.dart:214-217.
class SelfInvalidatingPolicy extends NavigationPolicy<TestRoute> {
  SelfInvalidatingPolicy(this.part);

  final SnapshotPart<bool> part;
  int decideCalls = 0;

  @override
  List<SnapshotPart<Object?>> get parts => [part];

  @override
  RouteDecision<TestRoute> decide() {
    decideCalls++;
    part.read();
    part.invalidate();
    return const RouteGo<TestRoute>(TestRoute.home);
  }
}

void main() {
  test('wait does not navigate', () {
    final target = RecordingTarget();
    NavigationBinding<TestRoute>(
      policy: GatePolicy(
        signedIn: SnapshotPart<bool>.loading('auth'),
        detail: SnapshotPart<bool>.loading('detail'),
      ),
      target: target,
    ).start();

    expect(target.navigations, isEmpty);
  });

  test('stay never navigates', () {
    final target = RecordingTarget();
    final binding =
        NavigationBinding<TestRoute>(policy: StayPolicy(), target: target)
          ..start();

    expect(target.navigations, isEmpty);
    expect(binding.lastDecision, const RouteStay<TestRoute>());
  });

  test('go navigates once and fires onNavigated once', () {
    final target = RecordingTarget();
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: SnapshotPart<bool>.loading('detail'),
    );
    final binding =
        NavigationBinding<TestRoute>(policy: policy, target: target)..start();

    binding.evaluate();
    binding.evaluate();

    expect(target.navigations, [TestRoute.login]);
    expect(policy.navigated, [TestRoute.login]);
  });

  test('does not navigate twice when current lags behind go', () {
    final target = RecordingTarget()..lagging = true;
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: SnapshotPart<bool>.loading('detail'),
    );
    final binding =
        NavigationBinding<TestRoute>(policy: policy, target: target)..start();

    binding.evaluate();

    expect(target.navigations, [TestRoute.login]);
  });

  test('onNavigated does not fire when already at the destination', () {
    final target = RecordingTarget(TestRoute.login);
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: SnapshotPart<bool>.loading('detail'),
    );
    NavigationBinding<TestRoute>(policy: policy, target: target).start();

    expect(target.navigations, isEmpty);
    expect(policy.navigated, isEmpty);
  });

  test('re-evaluates when a read part settles', () async {
    final target = RecordingTarget();
    NavigationBinding<TestRoute>(
      policy: GatePolicy(
        signedIn: SnapshotPart<bool>(name: 'auth', load: () async => false),
        detail: SnapshotPart<bool>.loading('detail'),
      ),
      target: target,
    ).start();

    expect(target.navigations, isEmpty);
    await Future<void>.delayed(Duration.zero);
    expect(target.navigations, [TestRoute.login]);
  });

  test('does not subscribe to an unread part', () {
    final detail = SnapshotPart<bool>.ready('detail', true);
    final policy = GatePolicy(
      signedIn: SnapshotPart<bool>.ready('auth', false),
      detail: detail,
    );
    NavigationBinding<TestRoute>(policy: policy, target: RecordingTarget())
        .start();

    final before = policy.decideCalls;
    detail.invalidate();

    expect(policy.decideCalls, before);
  });

  test('a policy that invalidates inside decide does not overflow', () async {
    final policy = SelfInvalidatingPolicy(
      SnapshotPart<bool>(name: 'p', load: () => true),
    );
    NavigationBinding<TestRoute>(policy: policy, target: RecordingTarget())
        .start();

    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(policy.decideCalls, lessThan(50),
        reason: 'reruns must be coalesced, not recursed');
  });

  test('dispose stops re-evaluation', () async {
    final target = RecordingTarget();
    final binding = NavigationBinding<TestRoute>(
      policy: GatePolicy(
        signedIn: SnapshotPart<bool>(name: 'auth', load: () async => false),
        detail: SnapshotPart<bool>.loading('detail'),
      ),
      target: target,
    )..start();

    binding.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(target.navigations, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/impl/navigation_binding_test.dart`
Expected: FAIL — `NavigationBinding` is undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/impl/navigation_binding.dart`:
```dart
import 'dart:async';

import '../contracts/navigation_policy.dart';
import '../contracts/route_decision.dart';
import '../contracts/route_target.dart';
import '../contracts/snapshot_part.dart';
import 'evaluation_context.dart';

/// Runs a [NavigationPolicy] and applies its decisions to an [IRouteTarget].
///
/// The binding never captures a part's value and acts on it later: every
/// change re-runs the whole decision against current state, so a late answer
/// cannot produce a stale navigation, only another evaluation.
class NavigationBinding<TRoute> {
  /// Creates a binding over [policy] and [target].
  NavigationBinding({
    required NavigationPolicy<TRoute> policy,
    required IRouteTarget<TRoute> target,
  })  : _policy = policy,
        _target = target;

  final NavigationPolicy<TRoute> _policy;
  final IRouteTarget<TRoute> _target;
  final Set<SnapshotPart<Object?>> _subscribed = <SnapshotPart<Object?>>{};

  RouteDecision<TRoute>? _lastDecision;
  TRoute? _lastCommanded;
  bool _disposed = false;
  bool _evaluating = false;
  bool _rerunScheduled = false;

  /// The most recent decision, or null before the first evaluation.
  RouteDecision<TRoute>? get lastDecision => _lastDecision;

  /// Runs the first evaluation and begins reacting to part changes.
  void start() => evaluate();

  /// Runs the policy, updates subscriptions, and applies the decision.
  RouteDecision<TRoute> evaluate() {
    if (_disposed) return _lastDecision ?? RouteWait<TRoute>();
    if (_evaluating) {
      _scheduleRerun();
      return _lastDecision ?? RouteWait<TRoute>();
    }

    _evaluating = true;
    try {
      final context = EvaluationContext();
      final decision = EvaluationContext.track(context, _policy.decide);
      _resubscribe(context.reads);
      _lastDecision = decision;
      _apply(decision);
      return decision;
    } finally {
      _evaluating = false;
    }
  }

  /// Stops reacting to part changes.
  void dispose() {
    _disposed = true;
    for (final part in _subscribed) {
      part.removeListener(_onPartChanged);
    }
    _subscribed.clear();
  }

  /// Coalesces onto a microtask rather than recursing: a policy that
  /// invalidates a part it also reads would otherwise re-enter [evaluate]
  /// without bound.
  void _scheduleRerun() {
    if (_rerunScheduled) return;
    _rerunScheduled = true;
    scheduleMicrotask(() {
      _rerunScheduled = false;
      if (!_disposed) evaluate();
    });
  }

  void _resubscribe(Set<Object> reads) {
    final next = reads.whereType<SnapshotPart<Object?>>().toSet();

    for (final part in _subscribed.difference(next)) {
      part.removeListener(_onPartChanged);
    }
    for (final part in next.difference(_subscribed)) {
      part.addListener(_onPartChanged);
    }

    _subscribed
      ..clear()
      ..addAll(next);
  }

  void _apply(RouteDecision<TRoute> decision) {
    if (decision is! RouteGo<TRoute>) return;
    final destination = decision.to;
    if (_lastCommanded == destination) return;
    if (_target.current == destination) return;

    _lastCommanded = destination;
    _target.go(destination);
    _policy.onNavigated(destination);
  }

  void _onPartChanged() {
    if (_disposed) return;
    if (_evaluating) {
      _scheduleRerun();
      return;
    }
    evaluate();
  }
}
```

Add to `lib/nav_snapshot.dart`:
```dart
export 'src/impl/navigation_binding.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/impl/navigation_binding_test.dart`
Expected: PASS (9 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/src/impl/navigation_binding.dart lib/nav_snapshot.dart test/impl/navigation_binding_test.dart
git commit -m "feat: add NavigationBinding with coalesced re-evaluation"
```

---

### Task 10: GoRouterTarget adapter

**Files:**
- Create: `lib/src/adapters/go_router_target.dart`
- Modify: `lib/nav_snapshot.dart`
- Test: `test/adapters/go_router_target_test.dart`

**Interfaces:**
- Consumes: `IRouteTarget` (Task 8).
- Produces: `class GoRouterTarget<TRoute> implements IRouteTarget<TRoute>` with `GoRouterTarget({required GoRouter router, required String Function(TRoute) routeName, required TRoute? Function(String) routeFromName})`.

- [ ] **Step 1: Write the failing test**

`test/adapters/go_router_target_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_snapshot/nav_snapshot.dart';

enum TestRoute { home, login }

String _nameOf(TestRoute route) => route.name;

TestRoute? _routeFrom(String name) {
  for (final route in TestRoute.values) {
    if (route.name == name) return route;
  }
  return null;
}

GoRouter _buildRouter() => GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (_, __) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reports the current route and navigates', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    final target = GoRouterTarget<TestRoute>(
      router: router,
      routeName: _nameOf,
      routeFromName: _routeFrom,
    );

    expect(target.current, TestRoute.home);

    target.go(TestRoute.login);
    await tester.pumpAndSettle();

    expect(target.current, TestRoute.login);
  });

  test('current is null before the router resolves a match', () {
    final target = GoRouterTarget<TestRoute>(
      router: _buildRouter(),
      routeName: _nameOf,
      routeFromName: _routeFrom,
    );

    expect(target.current, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/adapters/go_router_target_test.dart`
Expected: FAIL — `GoRouterTarget` is undefined.

- [ ] **Step 3: Write minimal implementation**

`lib/src/adapters/go_router_target.dart`:
```dart
import 'package:go_router/go_router.dart';

import '../contracts/route_target.dart';

/// Applies route decisions to a [GoRouter].
///
/// The enum-to-name mapping lives here and nowhere else, so route names stay
/// out of policy code and a typo is a compile error rather than a silent
/// no-op.
class GoRouterTarget<TRoute> implements IRouteTarget<TRoute> {
  /// Creates a target over [router].
  GoRouterTarget({
    required GoRouter router,
    required String Function(TRoute route) routeName,
    required TRoute? Function(String name) routeFromName,
  })  : _router = router,
        _routeName = routeName,
        _routeFromName = routeFromName;

  final GoRouter _router;
  final String Function(TRoute route) _routeName;
  final TRoute? Function(String name) _routeFromName;

  @override
  TRoute? get current {
    final name = _currentName();
    if (name == null) return null;
    return _routeFromName(name);
  }

  @override
  void go(TRoute route) => _router.goNamed(_routeName(route));

  /// `GoRouter.state` throws on an empty match list before the first frame
  /// resolves, which is exactly when a boot policy runs.
  String? _currentName() {
    try {
      return _router.state.name;
    } on StateError {
      return null;
    }
  }
}
```

Add to `lib/nav_snapshot.dart`:
```dart
export 'src/adapters/go_router_target.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/adapters/go_router_target_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/src/adapters/go_router_target.dart lib/nav_snapshot.dart test/adapters/go_router_target_test.dart
git commit -m "feat: add GoRouterTarget adapter"
```

---

### Task 11: Core purity guard and documentation

**Files:**
- Create: `test/architecture/core_purity_test.dart`, `README.md`, `INTEGRATION_GUIDE.md`

**Interfaces:**
- Consumes: everything.
- Produces: no new public names.

- [ ] **Step 1: Write the guard test**

`test/architecture/core_purity_test.dart`:
```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contracts and impl never import Flutter or go_router', () {
    final offenders = <String>[];

    for (final dir in ['lib/src/contracts', 'lib/src/impl']) {
      final directory = Directory(dir);
      if (!directory.existsSync()) continue;

      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        for (final line in entity.readAsLinesSync()) {
          final trimmed = line.trimLeft();
          if (!trimmed.startsWith('import ') &&
              !trimmed.startsWith('export ')) {
            continue;
          }
          if (trimmed.contains('package:flutter/') ||
              trimmed.contains('package:go_router/')) {
            offenders.add('${entity.path}: $trimmed');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Core must stay portable; adapters belong in lib/src/adapters.',
    );
  });

  test('contracts never imports impl except for evaluation_context', () {
    final offenders = <String>[];
    final directory = Directory('lib/src/contracts');

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      for (final line in entity.readAsLinesSync()) {
        final trimmed = line.trimLeft();
        if (!trimmed.startsWith('import ')) continue;
        if (trimmed.contains('../impl/') &&
            !trimmed.contains('evaluation_context.dart')) {
          offenders.add('${entity.path}: $trimmed');
        }
      }
    }

    expect(offenders, isEmpty);
  });
}
```

- [ ] **Step 2: Run the guard test**

Run: `flutter test test/architecture/core_purity_test.dart`
Expected: PASS. This guards against future regression rather than driving new
code. If it fails now, an earlier task leaked an import into core — fix that
before continuing.

- [ ] **Step 3: Write README.md**

```markdown
# nav_snapshot

Navigation state snapshots with lazy pull parts, stream-fed push parts,
per-part invalidation, retry, and automatic route re-decision.

## The problem

Apps decide where to land the user at startup based on slow inputs: stored
keys, a token refresh, a provider API call. That means caching answers,
invalidating them, re-deciding when they change, and ignoring answers that
arrive too late. Hand-rolling that per app produces a different bug in each.

## Two ways a value arrives

**Push** — the value is already in memory and a stream fires when it changes:

    final hasKeys = SnapshotPart<bool>.observed(
      name: 'hasKeys',
      read: () => keyRepo.currentStatus == KeyStatus.ready,
      changes: keyRepo.statusChanges,
    );

**Pull** — nothing will tell you it went stale, so you ask:

    final serverExists = SnapshotPart<bool>(
      name: 'serverExists',
      load: () => provider.checkInstance(),
      retry: const RetryConfig(maxAttempts: 3, delay: Duration(seconds: 2)),
    );

Most inputs are push. A push part is ready immediately and never passes
through a loading state.

## The policy

    enum BootRoute { onboarding, home }

    class MyPolicy extends NavigationPolicy<BootRoute> {
      MyPolicy(this.hasKeys);
      final SnapshotPart<bool> hasKeys;

      @override
      List<SnapshotPart<Object?>> get parts => [hasKeys];

      @override
      RouteDecision<BootRoute> decide() {
        final keys = hasKeys.read();
        if (keys is! PartReady<bool>) return const RouteWait<BootRoute>();
        return keys.value
            ? const RouteGo<BootRoute>(BootRoute.home)
            : const RouteGo<BootRoute>(BootRoute.onboarding);
      }
    }

Wire it once:

    NavigationBinding<BootRoute>(
      policy: MyPolicy(hasKeys),
      target: GoRouterTarget<BootRoute>(
        router: router,
        routeName: (r) => r.name,
        routeFromName: _routeFromName,
      ),
    ).start();

## Why parts are lazy

A pull part loads on first read. A branch your policy does not reach never
fetches. That is how an expensive check stays skipped without configuring
anything — the read sits inside the branch that needs it.

## Why RouteWait is not RouteStay

`RouteWait` means the inputs have not resolved. `RouteStay` means they have,
and the answer is to leave the user alone. Both do nothing right now; they
mean different things, and merging them is how a router navigates on a guess.

## decide() must be synchronous

Dependency tracking is ambient and does not survive an `await`.
```

- [ ] **Step 4: Write INTEGRATION_GUIDE.md**

Document, with runnable snippets: (1) choosing push vs pull for an input, with
a table mapping common sources — a repository getter plus a change stream, a
one-shot API call, a value behind a Cubit — to the right constructor;
(2) `RetryConfig` with `retryOnValue`, and reading `exhausted` off a
`PartReady`; (3) `cacheKey` for an answer that is only valid for a given
identity; (4) invalidating a part from a Cubit after a state change;
(5) implementing `onNavigated` to hold cross-evaluation memory, and why that
state must not be written inside `decide()`; (6) table-testing a policy with
`SnapshotPart.ready` / `.loading` / `.failed`, no widget tree and no fakes;
(7) the app-side patterns the library deliberately does not cover — a minimum
boot duration, and edge-triggered invalidation from a transition in an
observed value.

- [ ] **Step 5: Run the whole suite and analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass; analyzer reports no issues.

- [ ] **Step 6: Commit**

```bash
git add test/architecture/core_purity_test.dart README.md INTEGRATION_GUIDE.md
git commit -m "test(architecture): guard core imports; document usage"
```

---

## Done when

- `flutter test` passes and `flutter analyze` is clean.
- No file under `lib/src/contracts/` or `lib/src/impl/` imports Flutter or go_router.
- A policy can be table-tested with seeded parts, no widget tree, no fakes.
- A push part never passes through `PartLoading`.
- `invalidate()` cancels in-flight loads and backoff chains.
- An exhausted value retry is observable on `PartReady`.
- A policy that invalidates a part inside `decide()` does not overflow the stack.
- No consumer app has been modified. Migration is a separate plan.
