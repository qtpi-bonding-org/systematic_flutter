import 'package:freezed_annotation/freezed_annotation.dart';

part 'control_behavior.freezed.dart';

/// What kind of control this is. Maps onto Flutter's semantics flags and
/// `SemanticsRole` inside `SystematicSemantics`.
enum ControlRole {
  /// No role of its own: a label, id or state added to something that already
  /// carries its own semantics (a `TextField`, a container).
  none,
  button,
  link,
  textField,
  header,
  image,
  tab,
  tabBar,
  checkbox,
  switchToggle,
  status,
  alert,
  loadingSpinner,
}

/// What a control is and what condition it is in.
///
/// Invalid combinations are rejected when the value is built: Flutter asserts
/// on a tab without `selected`, and on a `status`/`alert` that is also a live
/// region.
@freezed
abstract class ControlBehavior with _$ControlBehavior {
  @Assert(
    'role != ControlRole.tab || selected != null',
    'A tab must say whether it is selected',
  )
  @Assert(
    'role != ControlRole.switchToggle || toggled != null',
    'A switch must say whether it is on',
  )
  @Assert(
    'role != ControlRole.checkbox || checked != null',
    'A checkbox must say whether it is checked',
  )
  @Assert(
    '!liveRegion || (role != ControlRole.status && role != ControlRole.alert)',
    'status and alert roles are already announced; do not also set liveRegion',
  )
  const factory ControlBehavior({
    required ControlRole role,
    bool? selected,
    bool? expanded,
    bool? toggled,
    bool? checked,
    @Default(true) bool enabled,
    @Default(false) bool liveRegion,
  }) = _ControlBehavior;
}
