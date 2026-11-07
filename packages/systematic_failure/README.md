# systematic_failure

## Why

A pure-Dart vocabulary for separating bugs, domain failures, and environmental failures. It preserves localized keys for UI without leaking error text into user-facing messages.

## Use

Classify errors with `classify`, configure the generic key at startup with `configureFailurePolicy`, and use `describeError` only for agent tool results and debug output—not UI text or the error inbox.

## Testing

Import `package:systematic_failure/testing.dart` for `expectFailure` and `resetFailurePolicy`. The package has no Flutter dependency and can be used by portable application layers.
