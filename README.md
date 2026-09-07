# nav_snapshot

Navigation state snapshots with lazy pull parts, stream-fed push parts,
per-part invalidation, retry, and automatic route re-decision.

## The problem

Apps decide where to land the user at startup based on slow inputs: stored
keys, a token refresh, a provider API call. Doing that correctly means
caching answers, invalidating them, re-deciding when they change, and
ignoring answers that arrive too late. Hand-rolled per app, it produces a
different bug in each one.

This library does that job. It does **not** decide your routes — you write a
plain function for that.

## Two ways a value arrives

**Push** — the value is already in memory and a stream fires when it changes.
This is most inputs.

```dart
final hasKeys = SnapshotPart<bool>.observed(
  name: 'hasKeys',
  read: () => keyRepo.status == KeyStatus.ready,
  changes: keyRepo.statusChanges,
);
```

A push part is `PartReady` from construction and never re-enters
`PartLoading`. Routing a value you already have through a loading state would
manufacture an "I don't know" and flash the user back to a boot screen.

**Pull** — nothing will tell you it went stale, so you ask.

```dart
final serverExists = SnapshotPart<Instance>(
  name: 'serverExists',
  load: () => provider.checkInstance(),
  retry: const RetryConfig(maxAttempts: 3, delay: Duration(seconds: 2)),
);
```

## The policy

```dart
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
```

Wire it once:

```dart
NavigationBinding<BootRoute>(
  policy: MyPolicy(hasKeys),
  target: GoRouterTarget<BootRoute>(
    router: router,
    routeName: (route) => route.name,
    routeFromName: (name) {
      for (final route in BootRoute.values) {
        if (route.name == name) return route;
      }
      return null;
    },
  ),
).start();
```

`TRoute` holds only the routes the *policy* decides. Every other route in your
app stays exactly as it is.

## Why parts are lazy

A pull part loads on first read. A branch your policy never reaches never
fetches. That is how an expensive check stays skipped without configuring
anything — the read sits inside the branch that needs it:

```dart
if (!signedIn.value) {
  final existence = serverExists.read();   // only asked for on this path
  ...
}
```

## Why RouteWait is not RouteStay

`RouteWait` means the inputs have not resolved. `RouteStay` means they have,
and the answer is to leave the user alone. Both do nothing right now. They
mean different things, and merging them is how a router navigates on a guess.

## decide() must be synchronous

Dependency tracking is ambient and does not survive an `await`. A read after a
suspension registers nothing, so the binding never re-evaluates for it. The
return type enforces this; the reason is worth knowing anyway.

## Cross-evaluation memory

State that has to persist between decisions belongs in `onDecisionApplied`,
not in `decide()`:

```dart
@override
void onDecisionApplied(BootRoute route, {required bool navigated}) {
  confirmed = latchKey;              // decided, whether or not we moved
  if (navigated) hasLeftBootScreen = true;   // only when the user moved
}
```

`decide()` runs on evaluations that conclude nothing. Writing memory there
records decisions that never happened.

## What this library deliberately does not do

- Own your route table, or ordinary user-driven navigation.
- Provide a rule engine. Your policy is an `if` statement.
- Time anything. A minimum splash duration is an app-side predicate.
- Bridge a transition into an invalidation. Observing an edge (a value
  *becoming* ready) and invalidating in response is app-side wiring.
