# flutter_error_privserver

Privacy-preserving error inbox for Flutter applications. Errors are classified by
`systematic_failure` into `bug`, `domain`, or `environment`; exception text and
user messages are never stored.

## Bootstrap

Configure the failure policy first, then configure this package:

```dart
configureFailurePolicy(const FailurePolicy(generic: ...));
ErrorPrivserver.configure(ErrorPrivserverConfig(
  storage: SharedPrefsErrorBoxStorage(),
  reporter: (entry) => api.send(entry.toReportJson()),
));
```

Every cubit should extend the app's base cubit that applies `ErrorPrivserverMixin`
(on `TryOperationCubit`). The mixin captures operation failures, while
`ErrorPrivserver.captureError` is available to services and background workers.
Both paths share the serialized inbox queue and retention pruning.

## Retention and build metadata

`RetentionPolicy` removes sent entries, age-expired entries, and then caps the
inbox (default 200 entries). `BuildInfo` records optional app version and commit.
Generate defines from this package's directory with:

```sh
flutter run --dart-define=APP_VERSION=... --dart-define=GIT_COMMIT=...
# or use tool/build_defines.sh as the shell command that prints the defines
```

The report JSON has schema version 1 and includes `bin`; `errorCode` is retained
as the bin name because the server requires a non-null string.
