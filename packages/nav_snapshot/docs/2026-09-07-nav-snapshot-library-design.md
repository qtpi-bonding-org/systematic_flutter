# nav_snapshot: a navigation state library

**Status:** design, revision 3. Library implemented; see the repo root.
**Package:** `nav_snapshot`, repo `flutter_nav_snapshot`, in `/Users/aicoder/Documents/my-libs`.
**Lineage:** extends the PocketCoder docs
`2026-08-30-unified-boot-routing-design.md` (three deciders collapsed into one)
and `2026-09-01-post-deploy-auth-routing-design.md` (harness gate reinstated).
Those unified *where* the decision is made. This extracts *how its inputs are
resolved* into a reusable library.

**Revision 3 incorporates:** a second Opus review that built and ran revision 2
(4 blockers), plus what surfaced while actually fixing them. Changes from
revision 2 are marked **[R3]**.

**Revision 2 incorporated:** an Opus review that built revision 1's code and ran
its tests (6 blockers, 5 serious concerns), and
`2026-09-07-pocketcoder-decide-paper-exercise.md`, which wrote PocketCoder's real
policy against revision 1 and found nine points of friction. Changes from
revision 1 are marked **[R2]**.

## Problem

Four apps ask the same question at launch — "where does the user land?" — and the
answer depends on something slow: reading keys from storage, refreshing a token,
calling a provider API.

That splits into two jobs. **Job 1:** find out the slow things, don't ask twice,
remember the answers, know when they went stale, re-decide when they change, and
don't act on an answer that arrived late. **Job 2:** given the answers, pick a
route.

Job 2 is an `if` statement. Job 1 is where the bugs live, and all four apps
hand-roll it differently:

| App | Job 2 | Job 1 as implemented today |
|---|---|---|
| `achaean` | 2 lines over `_hasAccount`/`_isGuest` | mutable statics; `setHasAccount()` mutates them but **nothing re-runs the redirect** |
| `episutra` | 1 line over `_hasKeys` | `bool?` static + async `redirect` + `resetKeyCheck()` that `OnboardingCubit` must remember to call |
| `quanitya` | same as episutra | same, copied |
| `pocketcoder` | 13-row matrix | epochs, a generation counter, two latches, a retry timer, an in-flight cache — 342 lines, 8 `fix(boot)` commits |

The rules differ per app and are cheap. The resolution machinery is identical in
intent and expensive to get right. The library takes job 1 only.

### Two ways a value arrives **[R2]**

Revision 1 modelled every input as something you fetch. The paper exercise showed
three of PocketCoder's five inputs — and *all* inputs in the other three apps —
are not fetches at all. The distinction is not sync vs async; it is **who knows
the value changed**:

- **Pull.** Nothing will tell you it went stale, so you decide when to ask again.
  An API call, a DB query. PocketCoder's existence check and harness probe.
- **Push.** The value is already in memory and a stream fires the moment it
  changes. `IServerReadinessCheck.current` + `readinessChanges`,
  `AuthSessionCoordinator.current` + `sessionChanges`, achaean's `_hasAccount`,
  episutra's `_hasKeys`.

Push *can* be forced through a pull-shaped API by calling `invalidate()` on every
stream emission, but the part then passes through `PartLoading` for at least a
microtask on every change — manufacturing an "I don't know" for a value the app
did know, which on boot flashes the user back to the boot screen. That is the
exact unknown-vs-false confusion this design exists to prevent.

Both are the same primitive with different feeding, not two primitives: a value
the policy reads, which the binding re-evaluates on change.

## Goal

A small library whose parts are always readable, refresh themselves, retry on a
configurable policy, and notify when they change — plus one interface that forces
consumers into roughly the right shape, and a GoRouter adapter.

## Non-goals

- **No rule engine.** No ordered rules, no priorities. Consumers write a plain
  function. Revisit only if a second app grows a non-trivial matrix.
- **No route table ownership.** `GoRoute` trees, paths, and builders stay in the app.
- **No user-driven navigation.** Only the boot/gate decision.
- **No PocketCoder concepts in the library.** Nothing named readiness, harness,
  deployment, or instance.
- **No boot-animation timing. [R2]** See "What stays app-side".
- Not a `Navigator` replacement.

## Architecture

```
  ┌─ LIBRARY ──────────────────────────────────────────────┐
  │  SnapshotPart<T>    pull: lazy load, cache, retry       │
  │    .observed(...)   push: stream-fed, never Loading [R2]│
  │  PartState<T>       Loading | Ready | Failed            │
  │                     + attempts / exhausted on all  [R2] │
  │  RetryConfig        attempts, delay, retry-on predicate │
  │  NavigationPolicy<TRoute>  decide() + onNavigated() [R2]│
  │  RouteDecision<TRoute>     Stay | Wait | Go             │
  │  IRouteTarget<TRoute>      where routes go              │
  │  NavigationBinding<TRoute> re-evaluation engine         │
  │  GoRouterTarget<TRoute>    adapter                      │
  └────────────────────────────────────────────────────────┘
```

### SnapshotPart

```dart
/// Pull: nothing will tell us this went stale.
SnapshotPart({
  required String name,
  required FutureOr<T> Function() load,
  RetryConfig<T>? retry,
  Object? Function()? cacheKey,   // [R2] self-invalidates when the key changes
});

/// Push: the value is already here and a stream announces changes. [R2]
SnapshotPart.observed({
  required String name,
  required T Function() read,
  required Stream<void> changes,
});

PartState<T> read();   // registers a dependency; starts a pull load if needed
PartState<T> peek();   // same value, registers nothing, starts nothing
void invalidate();
void dispose();
```

An observed part is `PartReady` from construction and never returns to
`PartLoading`. It cannot fail and ignores `RetryConfig`.

**A synchronous pull loader settles synchronously. [R2]** `await` on a non-Future
still suspends a microtask, so revision 1 forced a spurious `Wait` on the first
evaluation for facts that were already known. `read()` takes a sync fast path
when `load()` returns a non-Future.

**Laziness is structural.** A part `decide()` never reaches is never loaded. This
is what preserves PocketCoder's current call pattern and its tests asserting the
existence resolver and harness repository are *not* called on the signed-in path.

**`cacheKey` replaces manual keyed invalidation. [R2]** PocketCoder's existence
answer is keyed on `(epoch, instanceId)`; a single unkeyed slot forced racy
app-side invalidation.

### The generation counter moved; it was not deleted **[R2]**

Revision 1 claimed generation counters were unnecessary because the binding
re-derives. That is true of the *binding* and false of the *part*: revision 1's
`invalidate()` did not cancel a running load, so a superseded load overwrote a
newer one, a bare `invalidate()` resurrected the pre-invalidation value, and an
invalidate during retry backoff spawned a second attempt chain. All three
confirmed by execution.

`SnapshotPart` therefore owns an internal epoch, captured at attempt start,
incremented by `invalidate()`, and checked after every suspension. The win is
real but narrower than claimed: written once in the library instead of five times
per app.

### PartState

```dart
sealed class PartState<T> {
  final int attempts;      // [R2]
  final bool exhausted;    // [R2]
}
final class PartLoading<T> extends PartState<T> {}
final class PartReady<T>   extends PartState<T> { final T value; }
final class PartFailed<T>  extends PartState<T> { final Object error; }
```

`attempts` and `exhausted` live on the **base**, not only on `PartFailed`. A
value-triggered retry that exhausts its budget settles as `PartReady` holding the
last value — the value is legitimate, it just could not be improved on — and
revision 1 gave the policy no way to distinguish "unknown, first try" from
"unknown, gave up after three." That silently deleted the `instanceUnverifiable`
route.

### RetryConfig

Retry must be triggerable by a *value*, not only a thrown error:
`InstanceExistenceResult.unknown` is a successful return that PocketCoder retries.

```dart
const RetryConfig({
  int maxAttempts = 1,
  Duration delay = Duration.zero,
  Backoff backoff = Backoff.fixed,
  bool retryOnError = true,
  bool Function(T)? retryOnValue,
});
```

Library owns the **mechanism** (counting, timing, marking exhausted); the policy
owns the **meaning** (what exhaustion implies for routing).

### NavigationPolicy

```dart
abstract class NavigationPolicy<TRoute> {
  List<SnapshotPart<Object?>> get parts;

  /// MUST be synchronous. Ambient dependency tracking does not survive an
  /// `await`; an async decide() would silently record only the reads before
  /// its first suspension. [R2]
  RouteDecision<TRoute> decide();

  /// Called whenever a RouteGo was applied; `navigated` says whether the
  /// router was actually moved. [R3]
  void onDecisionApplied(TRoute route, {required bool navigated}) {}
}
```

**A post-decision hook is required, not optional. [R2]** PocketCoder's three
cross-evaluation memories cannot be written inside `decide()`, which runs on
evaluations that conclude nothing.

**[R3] Correcting revision 2.** Revision 2 called this hook `onNavigated` and
claimed all three memories "are written as a consequence of navigation actually
happening." That is wrong, and only one of the three qualifies:

| Memory | Written at | Conditional on navigating? |
|---|---|---|
| `_hasLeftBootScreen` | `boot_routing_decider.dart:330` | **Yes** — inside `if (navigating)` |
| `_confirmedLatchKey` | line 291, *before* `_navigate` | No — unconditional |
| `_lastDeployProgressRoute` | line 311, *after* `_navigate` | No — keyed on the requested route |

An `onNavigated` that fires only on movement therefore cannot express two of
them. Concretely it would lose the latch confirmation on the "already on chats"
path, so a later `temporarilyUnavailable` for that key routes to login instead
of being lenient — the behaviour `confirmed temporarilyUnavailable is lenient`
(`boot_routing_decider_test.dart:629`) exists to protect. Hence
`onDecisionApplied(route, {required bool navigated})`: it fires on every applied
decision, and the flag carries the distinction the policy needs.

### RouteDecision

`Stay` and `Wait` stay distinct. `Wait` means "I cannot decide yet"; `Stay` means
"I decided, leave the user alone." Collapsing them is the bug
`ServerReadinessStatus.resolving` was added to fix.

`TRoute` is the app's own enum, so decisions are compile-checked. **Only routes
the policy can decide belong in it** — seven for PocketCoder, not the ~43 in
`RouteNames`.

### NavigationBinding

1. Runs `decide()`, recording which parts were `read()`.
2. Subscribes to exactly those, recomputing the set each evaluation.
3. Re-runs when a subscribed part changes.
4. Applies: `Go` → navigate if not already there, then `onDecisionApplied`.

**Re-entrancy is bounded, not merely deferred. [R3]** Revision 1 called
`evaluate()` from inside `evaluate()` and reached a `StackOverflowError` at
8,462 calls. Revision 2 deferred the rerun to a microtask, which was worse:
Dart drains microtasks before timers, so an endless chain starved timers and
frames and the isolate hung silently — for a boot router, a frozen splash
screen with no error. Reruns now count toward `maxChainedReruns` (20) and throw
a `StateError` naming the subscribed parts; the count resets when a chain
settles.

**The binding keeps no memory of the route it last commanded. [R3]** Revision 2
added one to stop a double-navigate when `GoRouterTarget.current` lags a frame
behind. It could not be cleared correctly: no rule based on `current` can
separate "the router has not rebuilt" from "the user navigated away", and a
user on any route outside `TRoute` makes `current` report null, so the memory
suppressed the gate permanently. The binding compares against the live route
only, matching `boot_routing_decider.dart:320-332`. Commanding the same route
twice within a frame is harmless; a permanent lockout is not.

**A part must not swallow a listener's exception. [R3]** `SnapshotPart`
originally wrapped the loader, the settle and the listener notification in one
`try`, so an exception thrown by a listener was caught and reported as a load
failure — which silently swallowed the binding's own unsettleable-policy error.
Only the loader is guarded.

Late answers are not a correctness problem: the binding never captures a value
and acts on it later, it re-derives from current state on every change.

## What stays app-side, honestly

The paper exercise confirmed these cannot be library concepts:

- **The 9s fresh-install boot floor.** It applies only in the `notProvisioned`
  branch and only while `!_hasLeftBootScreen`. A timer part is unconditional from
  construction and cannot express "this deadline is void once we navigated" —
  it would freeze the user for six seconds after an early `deploymentProgress`
  push. Stays an app-side predicate. **[R2, was a library "part" in revision 1]**
- **`_confirmedLatchKey`** — leniency letting a `temporarilyUnavailable` session
  pass if this exact (instance, baseUrl, user) was previously confirmed.
- **`_lastDeployProgressRoute`** — suppression so onboarding's own forward
  navigation isn't yanked back to `deploymentProgress`.
- **`_hasLeftBootScreen`** — gates the boot floor. Unmentioned in revision 1
  despite being load-bearing. **[R2]**

All three memories become constructor-settable fields on the policy, written from
`onDecisionApplied`. `decide()` is therefore pure *given* its parts and its seeded
memories, not pure absolutely. Three of the four effect-layer `fix(boot)` commits
were latch bugs; the library does not prevent them, it only makes them testable
without a widget tree.

- **`AuthSessionCoordinator.restore()`** is an async *effect* with a `void`
  result, keyed on a ready-epoch derived from a readiness *transition*. Nothing in
  the library computes derived state from transitions, so the app observes
  readiness twice: inside `decide()`, and outside to detect the edge and
  invalidate. Documented pattern, not a library feature. **[R2]**

## Mapping PocketCoder onto it

| Today | Becomes |
|---|---|
| `resolving` → stay | `readiness.read().status == resolving` → `Wait()` |
| 9s boot floor | app-side predicate, read in the `notProvisioned` branch only |
| `notProvisioned` → onboarding | `Go(onboarding)`, via app-side deploy-phase guard |
| `provisioning` / `resumeUnrecoverable` | `Go(deploymentProgress)`, same guard |
| deployment auth `waitingForCredentials`/`signingIn` | `Wait()` |
| readiness / session / deployment-auth streams | `SnapshotPart.observed` |
| existence resolver, harness probe | `SnapshotPart` (pull) |
| existence keyed on `(epoch, instanceId)` | `cacheKey: () => (epoch, instanceId)` |
| unknown retry ×3 @ 2s | `RetryConfig(maxAttempts: 3, delay: 2s, retryOnValue: (v) => v == unknown)` |
| resolver throw → mapped to `unknown` | `PartFailed` and `PartReady(unknown, exhausted: true)` map to the same route; the policy must converge them explicitly |
| exhausted → instanceUnverifiable | `if (e.exhausted) return Go(instanceUnverifiable)` |
| `retryAuth()` | `auth.invalidate(); existence.invalidate();` |
| generation counter + 5 stale guards | moved into `SnapshotPart`'s epoch |
| `_inFlightRestore` / `_inFlightExistence` | part-level de-dup |
| `_currentRouteName()` StateError guard | `GoRouterTarget.current` |
| latch writes | `onDecisionApplied` |

## Testing

**Library.** Unit tests, no widget tree: lazy-load-on-first-read; unread part
never loads; sync loader settles synchronously; in-flight de-dup; invalidate one
leaves others; invalidate cancels an in-flight load; invalidate during backoff
does not double-chain; `cacheKey` change self-invalidates; retry on error and on
value predicate; exhausted marking on both `PartReady` and `PartFailed`; observed
part never enters `Loading`; observed part updates on stream emission; binding
subscribes only to read parts; dependency set recomputed not accumulated;
coalesced re-entrancy (including a policy that invalidates inside `decide()`);
`onNavigated` fires only on real navigation; no double-navigate within one frame;
`EvaluationContext.current` is null after an async gap.

**PocketCoder policy.** Table-driven over `decide()` with seeded parts and seeded
memories. One row per matrix line, including unknown-unexhausted vs
unknown-exhausted as distinct rows.

**Regression net. [R2, corrected]** Revision 1 promised the existing 858-line
`boot_routing_decider_test.dart` would stay green *unchanged*. It will not.
Today's retry counts per-reconcile-that-observed-unknown, keyed on
`(epoch, instanceId)`, and an unrelated emission mid-window increments it against
the cached answer without calling the resolver. `RetryConfig` counts loader
invocations inside one chain with no `decide()` between attempts. Observable
routing should match; the asserted resolver-call counts and timings at
`boot_routing_decider_test.dart:753-842` will need rewriting. Plan for it.

## Migration order

Deliberately not PocketCoder-first.

1. **Library + tests**, no consumer.
2. **achaean** — one observed part, 2-line policy. Fixes a real bug:
   `setHasAccount()` will actually re-run the decision.
3. **episutra**, then **quanitya** — deletes `resetKeyCheck()` and the `bool?`
   cache.
4. **API review gate.** Change the shape freely here.
5. **pocketcoder** — behind its existing suite: parts → policy → binding → delete
   decider internals.

## Risks

- **The API is still wrong somewhere PocketCoder will reveal.** Reduced, not
  eliminated: revision 2 exists because the paper exercise found `ObservedValue`
  missing, and that exercise is now the mitigation to repeat before step 5.
- **`EvaluationContext` is a plain static**, not zone-scoped, so it is safe only
  because `decide()` is synchronous by contract. Enforced by a test, not by types.
- **Read-tracking is implicit.** A part read inside a conditional that stops being
  reached must lose its subscription; the binding recomputes rather than
  accumulates. Covered by test.
- **`go_router` is a hard dependency** of a package whose core is deliberately
  free of it. Accepted for now; splitting `nav_snapshot_go_router` is the escape
  hatch if a non-GoRouter consumer appears. Version bound widened to `<18.0.0`
  — revision 1's `<17.0.0` already excluded the current line. **[R2]**
- **Four consumers, one API.** Every change is a four-repo change. Accepted: it is
  the cost of the shared component, versus four divergent bugs.
