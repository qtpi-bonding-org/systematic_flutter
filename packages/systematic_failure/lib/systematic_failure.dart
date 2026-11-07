/// Pure-Dart failure classification and stable error descriptions.
library;

export 'src/bin.dart';
export 'src/describe_error.dart';
export 'src/exceptions.dart';
export 'src/failure.dart';
export 'src/failure_kind.dart';
export 'src/policy.dart'
    show FailurePolicy, classify, configureFailurePolicy, failurePolicy;
