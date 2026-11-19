import 'package:flutter_error_privserver/flutter_error_privserver.dart';
// Only for the in-memory storage below. Nothing here is test-only at runtime.
import 'package:flutter_error_privserver/testing.dart';
import 'package:systematic_failure/systematic_failure.dart';
import 'package:systematic_failure/testing.dart';

import '../l10n/l10n_key_resolver.g.dart';

ErrorPrivserverConfig? _pending;

/// Sets the failure policy and the capture config. Nothing is captured until
/// [startErrorCapture] runs.
///
/// Captured errors go to a local inbox; nothing is sent (the reporter returns
/// false). [storage] defaults to in-memory storage: the spike has no database,
/// so captured errors last until the app quits.
void configureErrorCapture({ErrorBoxStorage? storage}) {
  configureFailurePolicy(FailurePolicy(generic: L10nKeys.errorGeneric));
  _pending = ErrorPrivserverConfig(
    storage: storage ?? InMemoryErrorBoxStorage(),
    reporter: (entry) async => false,
  );
}

/// Starts capture with the config from [configureErrorCapture].
///
/// The inbox's write queue belongs to the zone it is created in. Call this
/// from the app's own start (SpikeApp.initState), not from a test's setUp,
/// or the queued writes run where a widget test cannot flush them.
void startErrorCapture() {
  final config = _pending;
  if (config != null) ErrorPrivserver.configure(config);
}

/// Stops capture and clears the policy. For tests.
void resetErrorCapture() {
  _pending = null;
  ErrorPrivserver.reset();
  resetFailurePolicy();
}
