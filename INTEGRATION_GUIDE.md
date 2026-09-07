# nav_snapshot integration guide

## 1. Choosing push or pull for each input

Ask one question: **will something tell me when this changed?**

| Your source | Constructor |
|---|---|
| Repository getter + a change `Stream` | `SnapshotPart.observed` |
| A value behind a Cubit / `ValueNotifier` | `SnapshotPart.observed` (map its stream to `Stream<void>`) |
| A `bool` you set from elsewhere in the app | `SnapshotPart.observed`, plus a stream you emit on when you set it |
| One-shot API or provider call | `SnapshotPart(load: ...)` |
| Local storage read done once at boot | `SnapshotPart(load: ...)` |
| An async side effect you only need to *complete* | `SnapshotPart<void>(load: ...)` |

Getting this wrong is not fatal, but a push input modelled as a pull part will
flash through `PartLoading` on every change, and your policy will emit
`RouteWait` for a value the app already had.

```dart
// Push: a Cubit's state.
final session = SnapshotPart<SessionState>.observed(
  name: 'session',
  read: () => sessionCubit.state,
  changes: sessionCubit.stream.map((_) {}),
);
```

## 2. Retry, including retry on a *value*

A call can succeed and still not answer the question. A provider check that
returns a definite "I don't know" is worth asking again:

```dart
final existence = SnapshotPart<ExistenceResult>(
  name: 'existence',
  load: () => resolver.checkInstance(),
  retry: RetryConfig<ExistenceResult>(
    maxAttempts: 3,
    delay: const Duration(seconds: 2),
    retryOnValue: (value) => value == ExistenceResult.unknown,
  ),
);
```

Reading the outcome. Note `exhausted` sits on `PartState`, not only on
`PartFailed` — a value retry that spends its budget settles as a *successful*
`PartReady` holding the last value:

```dart
final e = existence.read();
if (e is PartLoading) return const RouteWait<AppRoute>();      // retrying
if (e.exhausted) return const RouteGo<AppRoute>(AppRoute.unverifiable);
if (e is PartFailed) return const RouteGo<AppRoute>(AppRoute.unverifiable);
if (e is PartReady<ExistenceResult>) {
  return switch (e.value) { ... };
}
```

`exhausted` on a `PartFailed` means a retry budget existed and is spent. A
first-try failure with `maxAttempts: 1`, or with `retryOnError: false`,
reports `exhausted: false` — there was never a budget to spend.

Converge a thrown error and a returned "don't know" explicitly if your app
treats them the same. The library keeps them distinct; only you know whether
they mean the same route.

## 3. cacheKey — an answer valid only for one identity

When an answer is only meaningful for a particular server, user, or session,
give the part a key. It self-invalidates when the key changes, with no
manual bookkeeping:

```dart
final existence = SnapshotPart<ExistenceResult>(
  name: 'existence',
  load: () => resolver.checkInstance(),
  cacheKey: () => (readiness.peek().valueOrNull?.instanceId, session.userId),
);
```

Use `peek()` inside a `cacheKey`, not `read()` — a key is evaluated on every
read and should not itself create dependencies.

## 4. Invalidating from a Cubit

Replaces the hand-rolled "reset the cache" flag:

```dart
class OnboardingCubit extends AppCubit<OnboardingState> {
  OnboardingCubit(this._hasKeys);
  final SnapshotPart<bool> _hasKeys;

  Future<void> completeSetup() async {
    await _repo.generateKeys();
    _hasKeys.invalidate();   // the binding re-decides on its own
  }
}
```

If `_hasKeys` is an observed part, prefer emitting on its stream — invalidate
is for pull parts.

## 5. Cross-evaluation memory via onDecisionApplied

Some state must survive between decisions: "we already confirmed this
session", "we pushed the progress screen", "we have left the boot screen".
None of it belongs in `decide()`, which runs on evaluations that conclude
nothing and would record decisions that never happened.

```dart
class MyPolicy extends NavigationPolicy<AppRoute> {
  MyPolicy({this.confirmedKey, this.hasLeftBoot = false});

  LatchKey? confirmedKey;      // constructor-settable so tests can seed it
  bool hasLeftBoot;

  @override
  void onDecisionApplied(AppRoute route, {required bool navigated}) {
    confirmedKey = _currentKey;
    if (navigated) hasLeftBoot = true;
  }
}
```

`navigated` is false when the decision resolved to the route already showing.
Both cases are real: a latch recording "we reached this conclusion" fires
either way; "the user moved" fires only when `navigated` is true.

## 6. Testing a policy

No widget tree, no fakes, no router. Seed the parts and call `decide()`:

```dart
final rows = <({String name, bool? keys, RouteDecision<AppRoute> expected})>[
  (name: 'unresolved', keys: null, expected: const RouteWait<AppRoute>()),
  (name: 'has keys',   keys: true, expected: const RouteGo<AppRoute>(AppRoute.home)),
  (name: 'no keys',    keys: false, expected: const RouteGo<AppRoute>(AppRoute.onboarding)),
];

for (final row in rows) {
  final keys = row.keys;
  final policy = MyPolicy(
    hasKeys: keys == null
        ? SnapshotPart<bool>.loading('hasKeys')
        : SnapshotPart<bool>.ready('hasKeys', keys),
  );
  expect(policy.decide(), row.expected, reason: row.name);
}
```

`SnapshotPart.ready` / `.loading` / `.failed` never load. Seed policy memory
through the constructor to test latch-dependent branches.

To assert a part is *not* consulted on some path — the usual reason laziness
matters — track the evaluation:

```dart
final context = EvaluationContext();
EvaluationContext.track(context, policy.decide);
expect(context.reads, isNot(contains(expensivePart)));
```

## 7. What stays in your app

**A minimum splash duration.** A part is an unconditional timer from
construction and cannot express "this deadline is void once we have
navigated". Keep it as a predicate the policy reads:

```dart
if (!hasLeftBoot && !bootFloorElapsed()) return const RouteWait<AppRoute>();
```

**Edge-triggered invalidation.** "When readiness *becomes* ready, re-run the
session restore" is a transition, and the library has no concept of one.
Observe it outside the policy:

```dart
readinessChanges.listen((snapshot) {
  final becameReady = snapshot.isReady && !_wasReady;
  _wasReady = snapshot.isReady;
  if (becameReady) restore.invalidate();
});
```

**Suppression rules about where the user is allowed to be.** "Do not yank
them back to the progress screen once they have moved on" encodes your
product's intent, not a routing mechanic. Keep it in the policy, backed by
memory written in `onDecisionApplied`.

## 8. If the binding throws

`NavigationBinding re-evaluated 20 times without settling` means a policy
invalidates a part it also reads on every pass, so the decision can never
converge. The message names the subscribed parts. Either stop invalidating
inside `decide()`, or scope the invalidation to the branch that genuinely
changed state.

This throws rather than spinning because reruns are scheduled as microtasks,
and Dart drains microtasks before timers — an unbounded chain starves timers
and frames, and would hang the app with no error at all.
