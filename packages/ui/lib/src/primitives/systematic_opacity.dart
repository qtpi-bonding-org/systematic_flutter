import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// How strongly a color shows in each state, as a [ThemeExtension]. Named by
/// meaning, not by number: a widget says `disabled` and the theme decides how
/// faint that is, for the whole app or one subtree.
///
/// Read it as `context.opacity`. Without an extension in the theme, widgets use
/// [SystematicOpacity.standard], the values [AppSizes] already carries.
@immutable
class SystematicOpacity extends ThemeExtension<SystematicOpacity> {
  const SystematicOpacity({
    required this.full,
    required this.hover,
    required this.inactive,
    required this.disabled,
    required this.ghost,
  });

  const SystematicOpacity.standard()
      : full = 1.0,
        hover = 0.7,
        inactive = 0.4,
        disabled = 0.38,
        ghost = 0.06;

  /// The nearest opacities in the theme, or [SystematicOpacity.standard].
  static SystematicOpacity of(BuildContext context) =>
      Theme.of(context).extension<SystematicOpacity>() ??
      const SystematicOpacity.standard();

  /// Focused and fully active.
  final double full;

  /// Hover and secondary emphasis.
  final double hover;

  /// Inactive chrome and non-text dividers. Not for text: contrast is too low.
  final double inactive;

  /// Disabled controls (the Material value).
  final double disabled;

  /// A barely visible fill for fields at rest.
  final double ghost;

  @override
  SystematicOpacity copyWith({
    double? full,
    double? hover,
    double? inactive,
    double? disabled,
    double? ghost,
  }) =>
      SystematicOpacity(
        full: full ?? this.full,
        hover: hover ?? this.hover,
        inactive: inactive ?? this.inactive,
        disabled: disabled ?? this.disabled,
        ghost: ghost ?? this.ghost,
      );

  @override
  SystematicOpacity lerp(ThemeExtension<SystematicOpacity>? other, double t) {
    if (other is! SystematicOpacity) return this;
    double mix(double a, double b) => lerpDouble(a, b, t) ?? a;
    return SystematicOpacity(
      full: mix(full, other.full),
      hover: mix(hover, other.hover),
      inactive: mix(inactive, other.inactive),
      disabled: mix(disabled, other.disabled),
      ghost: mix(ghost, other.ghost),
    );
  }
}

extension SystematicOpacityContext on BuildContext {
  /// The state opacities for this part of the tree.
  SystematicOpacity get opacity => SystematicOpacity.of(this);
}
