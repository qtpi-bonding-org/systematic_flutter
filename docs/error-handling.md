# Error handling (rules for people and coding agents)

One scheme, enforced by lints. Three bins, one sort function, one inbox, no free text.

## The three bins

| Bin | What lands in it | You write |
|---|---|---|
| **bug** | a Dart `Error` (`StateError`, `TypeError`, ...); a Rust panic if the app's `isBug` says so | nothing: do not throw `StateError` for an expected failure |
| **domain** | exceptions we write: `class X extends DomainException<XKind>` | a kind enum value, its ARB key, `throw X(kind: ...)` |
| **environment** | everything else (SQLite, network, disk, a Rust failure) and `EnvironmentException` subclasses | nothing, unless a caller must branch on it or the feature needs its own message |

`classify(error)` (package `systematic_failure`) does the sorting. Nothing else sorts, so nothing can be forgotten.

## What you write

1. A kind enum that implements `FailureKind`; every value supplies its message (an ARB-backed `L10nKey`, or `null` for the generic message). The compiler enforces this.
2. The ARB entry for that message.
3. `throw X(kind: XKind.something)`. Exceptions take no string: no message, no interpolated data.

```dart
enum NoteKind implements FailureKind {
  missing(L10nKeys.noteMissing),
  locked(null);
  const NoteKind(this.message);
  @override
  final L10nKey? message;
}

class NoteException extends DomainException<NoteKind> {
  const NoteException({required super.kind});
}
```

## Rules

- Never catch and convert. The only allowed conversion is a typed `on SpecificType catch (e)` that throws one of our two bases. A bare `catch` that throws a new domain/environment exception is a bug (`no_bare_catch_conversion`).
- Every class implementing `Exception` extends `DomainException` or `EnvironmentException` (`exceptions_extend_failure_base`). Every `throw` of an exception uses one of those (`throw_only_failure_types`); rethrowing a caught value is fine.
- Never turn an error into text: no `error.toString()`, no `'$error'` (`no_error_to_text`). Logger arguments are exempt. The only error-to-text function is `describeError`, for the agent's tool result and debug output.
- State: failures go through `tryOperation`, or `reportFailure(error, stack)` for stream errors and other paths that cannot use it. Never put a `String` in `state.error` (`no_string_error_in_state`); validation messages that are not failures get their own state field.
- UI text for a failure comes from the toast chain (feature mapper, then `ClassifyingExceptionKeyMapper`, then the generic key). A view that shows a failure inline uses the app's `safeErrorText`, never the error's text.

## The cubit recipe

Dart has single inheritance, so each app writes its own three-line base:

```dart
abstract class AppCubit<S extends IUiFlowState> extends TryOperationCubit<S>
    with ErrorPrivserverMixin<S> {
  AppCubit(super.initialState);
}
```

Every cubit extends it. `tryOperation` failures are logged, shown by the listener, and recorded in the inbox once.

## Bootstrap order

```dart
configureFailurePolicy(FailurePolicy(isBug: (e) => e is Error || e is PanicException, generic: L10nKeys.errorUnknown));
ErrorPrivserver.configure(ErrorPrivserverConfig(storage: ..., reporter: ..., retention: const RetentionPolicy(), buildInfo: const BuildInfo.fromEnvironment()));
```

Run the app with `--dart-define`s from `packages/error_privserver/tool/build_defines.sh` so rows carry the app version and commit.

## The inbox

A row has: bin, errorType (the runtime type name), kind (domain only), source (the cubit's type), stack trace, appVersion, commit. No message, no code string. Group by errorType, kind and commit; with obfuscation on, keep the obfuscation map for each commit. Each app sets a `RetentionPolicy` (row cap, maximum age per bin, whether sent rows are pruned).

## Tests

`systematic_failure/testing.dart`: `resetFailurePolicy()`, `expectFailure(error, bin:, kind:)`. `error_privserver/testing.dart`: `InMemoryErrorBoxStorage`; call `ErrorPrivserver.reset()` in `tearDown`.

## Lints and options

Rules live in `packages/lints`; options go in the app's `lint_config.yaml` (generated paths to exclude, logger types to exempt, state mutator names). The ratchet script in `packages/lints/tool` keeps the baseline from growing.
