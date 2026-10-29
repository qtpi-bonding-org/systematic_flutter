import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:l10n_key_resolver/runtime.dart';

part 'spoken_text.freezed.dart';

/// What a screen reader says about a control, and what a sighted user reads.
///
/// Every part is a [Label]: a generated `L10nKey` (spoken in the user's
/// language) or an explicit `DataText` (runtime data). A plain `String`
/// cannot be passed. `QtpiSemantics` resolves the labels through the nearest
/// `LabelScope`.
///
/// For a control with visible text, the visible `Text` is rendered from [label]
/// so the two cannot drift. Icon-only controls use the same label for the
/// tooltip and the accessible name.
///
/// A const constructor cannot compare values, so an empty `DataText` label is
/// rejected by `QtpiSemantics` in debug builds.
@freezed
abstract class SpokenText with _$SpokenText {
  const factory SpokenText({
    required Label label,

    /// What activating the control will do, when the label alone is not enough.
    Label? hint,

    /// Current value, for controls that have one (a slider, a progress count).
    Label? value,
  }) = _SpokenText;
}
