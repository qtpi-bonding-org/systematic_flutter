import 'package:flutter/foundation.dart';
import 'package:l10n_key_resolver/runtime.dart';

// UI Flow State
enum UiFlowStatus {
  idle,
  loading,
  success,
  failure,
}

extension UiFlowStatusExtension on UiFlowStatus {
  bool get isIdle => this == UiFlowStatus.idle;
  bool get isLoading => this == UiFlowStatus.loading;
  bool get isSuccess => this == UiFlowStatus.success;
  bool get isFailure => this == UiFlowStatus.failure;
}

abstract class IUiFlowState {
  UiFlowStatus get status;
  Object? get error;

  /// The state to emit when an operation starts loading: same data,
  /// [status] transitioned to [UiFlowStatus.loading], [error] cleared.
  ///
  /// Called by [TryOperationCubit]/[TryOperationMixin]/[TryOperationExtension]
  /// instead of guessing at a `copyWith(status:, error:)` shape via a dynamic
  /// call — implement this explicitly so the compiler (not a runtime
  /// `NoSuchMethodError`) catches a state that can't represent loading.
  /// A flat, single-shape state normally mixes in [UiFlowStateMixin] and
  /// gets this for free; a sealed union overrides it to return its own
  /// `.loading()` variant.
  IUiFlowState withLoading();

  /// The state to emit when an operation fails: same data, [status]
  /// transitioned to [UiFlowStatus.failure], carrying [error].
  ///
  /// See [withLoading] for why this exists as an explicit method rather
  /// than a dynamic `copyWith` call.
  IUiFlowState withError(Object error);

  bool get isIdle => status == UiFlowStatus.idle;
  bool get isLoading => status == UiFlowStatus.loading;
  bool get isSuccess => status == UiFlowStatus.success;
  bool get isFailure => status == UiFlowStatus.failure;
  bool get hasError => error != null;
}

mixin UiFlowStateMixin implements IUiFlowState {
  /// Default implementation for flat, single-shape states: relies on a
  /// generated/hand-written `copyWith({status, error, ...})` existing on
  /// the mixing-in class (true for every `@freezed` state with `@Default`
  /// fields, which is what this mixin is meant for). States that can't
  /// satisfy that shape — sealed unions, for instance — should implement
  /// [IUiFlowState] directly and override [withLoading]/[withError]
  /// themselves instead of using this mixin.
  @override
  IUiFlowState withLoading() => (this as dynamic)
      .copyWith(status: UiFlowStatus.loading, error: null) as IUiFlowState;

  @override
  IUiFlowState withError(Object error) => (this as dynamic)
      .copyWith(status: UiFlowStatus.failure, error: error) as IUiFlowState;

  @override
  bool get isIdle => status == UiFlowStatus.idle;

  @override
  bool get isLoading => status == UiFlowStatus.loading;

  @override
  bool get isSuccess => status == UiFlowStatus.success;

  @override
  bool get isFailure => status == UiFlowStatus.failure;

  @override
  bool get hasError => error != null;
}

// Message Key
enum MessageType {
  info,
  success,
  warning,
  error,
  loading,
}

/// A message to show: a [Label] (a generated `L10nKey`, or explicit
/// `DataText`) and how to present it. A raw string cannot be passed.
@immutable
class MessageKey {
  final Label label;
  final MessageType type;

  const MessageKey.info(this.label) : type = MessageType.info;
  const MessageKey.success(this.label) : type = MessageType.success;
  const MessageKey.warning(this.label) : type = MessageType.warning;
  const MessageKey.error(this.label) : type = MessageType.error;
  const MessageKey.loading(this.label) : type = MessageType.loading;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageKey && other.label == label && other.type == type;

  @override
  int get hashCode => Object.hash(label, type);

  @override
  String toString() => 'MessageKey(label: $label, type: $type)';
}

// Mappers
abstract class IExceptionKeyMapper {
  MessageKey? map(Object exception);
}

abstract class IDomainStateKeyMapper<S extends IUiFlowState> {
  MessageKey? map(S state);
}

abstract class IStateMessageMapper<S extends IUiFlowState> {
  MessageKey? map(S state);
}

// Services
@immutable
class FeedbackMessage {
  final String message;
  final MessageType type;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const FeedbackMessage({
    required this.message,
    required this.type,
    this.onTap,
    this.onDismiss,
  });
}

abstract class IFeedbackService {
  void show(FeedbackMessage message);
}

abstract class ILoadingService {
  void show();
  void hide();
}

abstract class IUiFlowService {
  void handleMessage(MessageKey key);
  void showLoading();
  void hideLoading();
  void handleState<S extends IUiFlowState>(S state, IStateMessageMapper<S> mapper);
}
/// Determinate progress payload. total == 0 means indeterminate.
@immutable
class UiFlowProgress {
  final String? label;
  final int current;
  final int total;

  const UiFlowProgress({this.label, this.current = 0, this.total = 0});

  bool get isDeterminate => total > 0;
  double? get fraction => total > 0 ? current / total : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiFlowProgress &&
          other.label == label &&
          other.current == current &&
          other.total == total);

  @override
  int get hashCode => Object.hash(label, current, total);

  @override
  String toString() =>
      "UiFlowProgress(label: $label, current: $current, total: $total)";
}

/// Opt-in interface: states that report determinate progress.
/// Separate from IUiFlowState so existing states compile unchanged.
abstract class IUiFlowProgressState implements IUiFlowState {
  UiFlowProgress? get progress;
}

abstract class IProgressService {
  void show(UiFlowProgress progress);
  void hide();
}