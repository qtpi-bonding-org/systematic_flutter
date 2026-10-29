/// Stable machine handle for a control, applied both as a `Key` and as
/// `Semantics.identifier`.
///
/// Not spoken to the user, never localized, and never derived from text that
/// changes. Convention for new ids: lowercase snake case with optional
/// dots/colons/dashes, for example `tab_rail.close`; ids that already existed as
/// test keys (`settingsButton`) stay valid. A repeated item (a list row) uses
/// [ControlId.item] so each instance is unique.
///
/// A `const` constructor cannot assert, so validity (non-empty, no whitespace)
/// is checked by `QtpiSemantics` in debug builds and by the semantics audit.
extension type const ControlId(String value) {
  static final RegExp _pattern = RegExp(r'^\S+$');

  /// Whether [value] is an acceptable id: non-empty and without whitespace.
  static bool isValid(String value) => _pattern.hasMatch(value);

  /// `group:itemId` for one entry of a repeated list.
  static ControlId item(String group, String itemId) {
    assert(isValid(group), 'Invalid ControlId group "$group"');
    assert(isValid(itemId), 'Invalid ControlId item id "$itemId"');
    return ControlId('$group:$itemId');
  }
}
