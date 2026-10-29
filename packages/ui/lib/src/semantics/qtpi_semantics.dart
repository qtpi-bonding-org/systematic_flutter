import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:l10n_key_resolver/runtime.dart';

import 'control_behavior.dart';
import 'control_id.dart';
import 'label_scope.dart';
import 'spoken_text.dart';

/// The one place a control's accessibility is declared.
///
/// Three separate concerns, composed here:
///  - [id]: stable machine handle, applied as a `Key` and as
///    `Semantics.identifier`.
///  - [text]: what is spoken (label, hint, value).
///  - [behavior]: the role and its state.
///
/// Merges with the child's own semantics (a child `Text` or `TextField` still
/// contributes), and the identifier lands on the same node as the child's
/// actions. For [ControlRole.textField] the label and enabled state are left to
/// the field itself, so the control is named once and the node still merges.
/// The wrapper's [onTap] adds a screen-reader action only; a pointer tap still
/// needs a gesture handler in the child (the design-system primitives already
/// have one).
class QtpiSemantics extends StatelessWidget {
  const QtpiSemantics({
    super.key,
    required this.id,
    required this.behavior,
    required this.child,
    this.text,
    this.onTap,
    this.onLongPress,
  });

  final ControlId id;

  /// What is spoken. Null means the control is named by its own content (a
  /// visible `Text`, a field's decoration), which cannot drift from what is
  /// shown. Supply it when there is no visible text (an icon button), and wrap
  /// any visible text in `ExcludeSemantics`, or the name is read twice.
  final SpokenText? text;
  final ControlBehavior behavior;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  // Not textField: a `TextField` sets its own enabled flag, and two nodes with
  // the same flag will not merge, which strands the identifier on a parent.
  static bool _hasEnabledState(ControlRole role) => switch (role) {
    ControlRole.button ||
    ControlRole.link ||
    ControlRole.tab ||
    ControlRole.checkbox ||
    ControlRole.switchToggle => true,
    _ => false,
  };

  static SemanticsRole? _semanticsRole(ControlRole role) => switch (role) {
    ControlRole.tab => SemanticsRole.tab,
    ControlRole.tabBar => SemanticsRole.tabBar,
    ControlRole.status => SemanticsRole.status,
    ControlRole.alert => SemanticsRole.alert,
    ControlRole.loadingSpinner => SemanticsRole.loadingSpinner,
    _ => null,
  };

  static bool _hasContent(SpokenText? text) => switch (text?.label) {
    DataText(:final value) => value.isNotEmpty,
    _ => true,
  };

  static String? _resolve(LabelResolver resolver, Label? label) =>
      label == null ? null : resolver.resolve(label);

  @override
  Widget build(BuildContext context) {
    assert(
      ControlId.isValid(id.value),
      'Invalid ControlId "${id.value}": must be non-empty with no whitespace',
    );
    assert(_hasContent(text), 'SpokenText.label must not be empty');
    final resolver = LabelScope.of(context);
    final role = behavior.role;
    final enabled = behavior.enabled;
    return KeyedSubtree(
      key: ValueKey<String>(id.value),
      child: Semantics(
        identifier: id.value,
        // A text field names itself from its own decoration (`labelText`);
        // a second label here would be read twice ("Name Name").
        label: role == ControlRole.textField
            ? null
            : _resolve(resolver, text?.label),
        hint: _resolve(resolver, text?.hint),
        value: _resolve(resolver, text?.value),
        role: _semanticsRole(role),
        button: role == ControlRole.button || role == ControlRole.tab
            ? true
            : null,
        link: role == ControlRole.link ? true : null,
        header: role == ControlRole.header ? true : null,
        image: role == ControlRole.image ? true : null,
        enabled: _hasEnabledState(role) ? enabled : null,
        selected: behavior.selected,
        expanded: behavior.expanded,
        toggled: behavior.toggled,
        checked: behavior.checked,
        liveRegion: behavior.liveRegion ? true : null,
        explicitChildNodes: role == ControlRole.tabBar,
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        child: child,
      ),
    );
  }
}
