# Paper exercise: PocketCoder's `decide()` against the proposed API

**Purpose:** write the hardest consumer's policy before building the library, to
find API defects while they are still free. Nothing here is committed to a
package. The output is the friction list at the end.

**Inputs:** `boot_routing_decider.dart` (342 lines, 13-row matrix), the revised
API from the review (B1–B6 fixes assumed in place).

---

## What PocketCoder actually has to work with

| Input | Real shape today | Fits `SnapshotPart`? |
|---|---|---|
| `IServerReadinessCheck` | `current` (sync) + `readinessChanges` (stream) + `initialize()` | **No** — already resolved, just observable |
| `AuthSessionCoordinator` | `current` (sync) + `sessionChanges` (stream) + `restore()` (async, once per epoch) | **Split** — an observable value *and* an async op |
| `IDeploymentAuthStatus?` | `current` (sync, nullable) + `changes` (stream) | **No** — observable |
| `IInstanceExistenceResolver?` | `checkInstanceExists()` (async, one-shot) | **Yes** |
| `IHarnessAuthRepository` | `hasEffectiveHarnessConnection()` (async, one-shot) | **Yes** |

Only two of five are the "slow thing you fetch once and cache" that
`SnapshotPart` models. This is visible immediately and is the exercise's first
and largest finding.

---

## The attempt

```dart
enum BootRoute {
  onboarding, login, harnessAuth, chats,
  deploymentProgress, instanceGone, instanceUnverifiable,
}

class PocketCoderPolicy extends NavigationPolicy<BootRoute> {
  PocketCoderPolicy({
    required this.readiness,      // ObservedValue<ServerReadinessSnapshot>  [F1]
    required this.session,        // ObservedValue<AuthSessionSnapshot>      [F1]
    required this.deploymentAuth, // ObservedValue<DeploymentAuthStatusSnapshot?> [F1]
    required this.authRestore,    // SnapshotPart<void>                      [F2]
    required this.existence,      // SnapshotPart<InstanceExistenceResult>?
    required this.harness,        // SnapshotPart<bool>
    required this.bootFloorElapsed, // bool Function()                       [F6]
    this.confirmedLatchKey,       // seeded for tests                        [F7]
    this.lastDeployProgressRoute, // seeded for tests                        [F7]
    this.hasLeftBootScreen = false,
  });

  LatchKey? confirmedLatchKey;
  BootRoute? lastDeployProgressRoute;
  bool hasLeftBootScreen;

  @override
  RouteDecision<BootRoute> decide() {
    final r = readiness.read();

    // ── A1..A3: pre-ready ────────────────────────────────────────────
    switch (r.status) {
      case ServerReadinessStatus.resolving:
        return const RouteWait<BootRoute>();

      case ServerReadinessStatus.notProvisioned:
        if (!hasLeftBootScreen && !bootFloorElapsed()) {   // [F6]
          return const RouteWait<BootRoute>();
        }
        return _deployPhase(BootRoute.onboarding);         // [F8]

      case ServerReadinessStatus.provisioning:
      case ServerReadinessStatus.resumeUnrecoverable:
        return _deployPhase(BootRoute.deploymentProgress); // [F8]

      case ServerReadinessStatus.ready:
        break;
    }

    // ── B: restore once per ready-epoch ──────────────────────────────
    if (authRestore.read() is! PartReady<void>) {          // [F2]
      return const RouteWait<BootRoute>();
    }

    // ── C: in-flight auto-login makes auth transient ─────────────────
    final da = deploymentAuth.read();
    if (da != null &&
        da.instanceId == r.instanceId &&
        (da.phase == DeploymentAuthPhase.waitingForCredentials ||
         da.phase == DeploymentAuthPhase.signingIn)) {
      return const RouteWait<BootRoute>();
    }

    // ── D: authOk ────────────────────────────────────────────────────
    final s = session.read();
    final latchKey = (r.instanceId, s.baseUrl, s.userId);
    final authOk = switch (s.state) {
      AuthSessionState.signedIn => true,
      AuthSessionState.temporarilyUnavailable => latchKey == confirmedLatchKey,
      AuthSessionState.signedOut => false,
    };

    if (s.state == AuthSessionState.signedIn) {
      existence?.invalidate();   // [F4] — mutation inside decide()
    }

    // ── E: signed out / unconfirmed ──────────────────────────────────
    if (!authOk) {
      final part = existence;
      if (part == null) return const RouteGo<BootRoute>(BootRoute.login);

      final e = part.read();
      switch (e) {
        case PartLoading<InstanceExistenceResult>():
          return const RouteWait<BootRoute>();             // covers E3 retry
        case PartFailed<InstanceExistenceResult>():
          return const RouteGo<BootRoute>(BootRoute.instanceUnverifiable); // [F5]
        case PartReady<InstanceExistenceResult>(
              value: final v, exhausted: final exhausted):
          if (v == InstanceExistenceResult.unknown && exhausted) {
            return const RouteGo<BootRoute>(BootRoute.instanceUnverifiable);
          }
          return switch (v) {
            InstanceExistenceResult.exists =>
              const RouteGo<BootRoute>(BootRoute.login),
            InstanceExistenceResult.gone =>
              const RouteGo<BootRoute>(BootRoute.instanceGone),
            InstanceExistenceResult.unknown =>
              const RouteWait<BootRoute>(),
          };
      }
    }

    // ── F0: already settled on chats ─────────────────────────────────
    if (latchKey == confirmedLatchKey && currentRoute == BootRoute.chats) { // [F3]
      return const RouteStay<BootRoute>();
    }

    // ── F1/F2: harness gate ──────────────────────────────────────────
    final h = harness.read();
    if (h is! PartReady<bool>) return const RouteWait<BootRoute>();

    confirmedLatchKey = latchKey;   // [F7] — written on decide, not on navigate
    return RouteGo<BootRoute>(
      h.value ? BootRoute.chats : BootRoute.harnessAuth,
    );
  }

  RouteDecision<BootRoute> _deployPhase(BootRoute route) {              // [F8]
    if (lastDeployProgressRoute != null && currentRoute != lastDeployProgressRoute) {
      return const RouteStay<BootRoute>();
    }
    return RouteGo<BootRoute>(route);
  }
}
```

It can be written. But every bracketed marker is a place the API had to be bent.

---

## Friction found

### F1 — `SnapshotPart` is the wrong primitive for three of five inputs (**API change**)

Readiness, session, and deployment-auth are not "fetch once and cache." They are
already-resolved values that change over time, with a synchronous `current` and a
stream. Modelling them as parts means: seed with a value, subscribe to the stream,
call `invalidate()` on every emission, let the part re-`load()` from `current`. That
is a fetch-shaped wrapper around something that was never a fetch, and it routes a
synchronously-available value through a `PartLoading` state it is never actually in.

The library needs a **second input primitive**:

```dart
class ObservedValue<T> {
  ObservedValue({required T Function() read, required Stream<void> changes});
  T read();          // sync, always a value, registers a dependency
}
```

Same dependency-tracking contract, no loading state, no retry. `SnapshotPart` keeps
its lazy-fetch job. This also answers review blocker **B5** properly: the stream
bridge is not a missing helper on `SnapshotPart`, it is a different primitive.

Cross-check against the other three apps: achaean's `_hasAccount`/`_isGuest` and
episutra's `_hasKeys` are *also* `ObservedValue`, not `SnapshotPart` — a sync local
read plus "something changed." **`ObservedValue` is the primitive all four apps need;
`SnapshotPart` is the one only PocketCoder needs.** The library was designed around
the rarer of the two.

### F2 — `restore()` is an async side effect, not a fact (**API gap**)

`_ensureRestoredFor(epoch)` calls `AuthSessionCoordinator.restore()`, whose result
is not read by anything — it publishes a new session snapshot as a side effect. Its
value is `void`. Modelling it as `SnapshotPart<void>` works but reads as a lie: the
policy reads a part solely to force an effect and gate on its completion.

Worse, its cache key is the ready-epoch, which is derived from a readiness
*transition* (`!_wasReady` → ready). Nothing in the library computes derived state
from transitions, so the app must observe readiness twice: once inside `decide()`,
and once outside to detect the edge and call `authRestore.invalidate()`.

Needs an explicit answer. Options: an `EffectPart<void>` that is honest about being
an effect; or a documented app-side pattern for edge-triggered invalidation.

### F3 — `currentRoute` has no dependency tracking (**confirms review S2**)

Two branches read the current route (F0's chats latch, F8's deploy-phase guard).
`IRouteTarget.current` is not a part, so reading it registers nothing and
user-driven navigation never triggers re-evaluation. F0 is the branch that must
*not* query the harness when the user is already on chats — a test asserts this
today. It only works if the route is a tracked input. Either `ObservedValue<TRoute>`
fed by the app, or the binding tracks the route it last commanded.

### F4 — `decide()` has to mutate to be faithful

`existence?.invalidate()` inside `decide()` ports
`boot_routing_decider.dart:214-217` directly. This is the exact pattern the review
drove to a stack overflow (B4), so it is only safe once coalescing is fixed — and
even then it means `decide()` is not read-only, which every other part of the design
assumes. Alternative: express it as "existence is keyed on session state," which
argues for keyed parts (F9).

### F5 — a thrown resolver error and a returned `unknown` must converge

Today `_existenceFor` catches every throw and maps it to
`InstanceExistenceResult.unknown` (`boot_routing_decider.dart:120-126`), so throw
and unknown are the same route. With a part, a throw is `PartFailed` and an unknown
is `PartReady` — two states the policy must map back together, as above. Works, but
it is a trap for anyone writing the next policy, and the spec's mapping table
doesn't mention it.

### F6 — the boot floor cannot be a part (**confirms review S1**)

`bootFloorElapsed` is a plain closure here, not a `SnapshotPart`, because the floor
is conditional on `!hasLeftBootScreen` and applies *only* in the `notProvisioned`
branch. A part is an unconditional timer from construction and has no way to express
"this deadline is void once we have navigated." Take the `minimumDuration` fallback,
or leave it app-side as written.

### F7 — latch writes still happen at the wrong time (**confirms review B6**)

`confirmedLatchKey = latchKey` sits in `decide()`, but today it is written only when
navigation actually proceeds. If `decide()` runs twice with no navigation between,
this version confirms the latch on the first run — which is precisely what the
`'duplicate latch on chats does not query or navigate'` test guards. `onNavigated`
is required, not optional. Same for `hasLeftBootScreen`.

### F8 — `_deployPhase` returning `RouteStay` loses information

The deploy-phase suppression is expressible, but note it returns `RouteStay` for
"suppressed" — the same value as "decided, leave them alone." A third meaning
(`RouteSuppressed`) is arguably warranted, or the binding should own suppression.
Not a blocker; flagging because `RouteStay`/`RouteWait` were split for exactly this
kind of reason.

### F9 — one part, one cache slot; PocketCoder needs keyed caches

Today the existence answer is keyed `(epoch, instanceId)` — a change to either
invalidates it. A `SnapshotPart` has a single unkeyed slot, so the app must watch
both and invalidate manually, and manual invalidation is racy until B2 is fixed.
Consider `SnapshotPart.keyed({required Object Function() key})` that self-invalidates
when the key changes.

---

## Verdict

The API survives, but not unchanged. Two findings are structural:

1. **`ObservedValue` is missing, and it is the primitive three of four apps
   actually need.** The library was built around `SnapshotPart`, which only
   PocketCoder needs. This inverts the emphasis of both the spec and the plan.
2. **`decide()` cannot be purely a read.** It must mutate latches, and faithfully
   it must invalidate a part. The `onNavigated` hook and fixed coalescing are
   prerequisites, not polish.

The rest (F2, F5, F6, F8, F9) are answerable within the current shape.

Doing this on paper cost about an hour and found one primitive that does not exist,
one that is over-emphasised, and confirmed three review blockers from a second
direction. Finding F1 at migration step 5 would have meant rewriting the core and
re-migrating three apps.
