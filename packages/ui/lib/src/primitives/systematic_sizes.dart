import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_spacings.dart';
import 'ui_scaler.dart';

/// The spacing unit, corner radii, icon sizes, border widths and control
/// heights as a [ThemeExtension], so a `Theme` can
/// change them for a whole app or one subtree.
///
/// The constructor takes the *unscaled* design values (8, 16, ...). The getters
/// apply [UiScaler] when they are read, so spacing still follows the screen
/// width live (a window resize or a rotation) and an override changes the base
/// once. Without an extension in the theme, widgets use
/// [SystematicSizes.standard], the same numbers [AppSizes] uses. Put an
/// instance in `ThemeData.extensions` to change spacing everywhere that reads
/// it: [VSpace], [HSpace], `context.padding` and `context.sizes`.
@immutable
class SystematicSizes extends ThemeExtension<SystematicSizes> {
  const SystematicSizes({
    required double space,
    required double spaceHalf,
    required double radiusTiny,
    required double radiusSmall,
    required double radiusMedium,
    required double radiusLarge,
    double iconTiny = 8,
    double iconSmall = 16,
    double iconMedium = 24,
    double iconLarge = 32,
    double iconXLarge = 48,
    double borderWidth = 1,
    double borderWidthThick = 2,
  })  : _space = space,
        _spaceHalf = spaceHalf,
        _radiusTiny = radiusTiny,
        _radiusSmall = radiusSmall,
        _radiusMedium = radiusMedium,
        _radiusLarge = radiusLarge,
        _iconTiny = iconTiny,
        _iconSmall = iconSmall,
        _iconMedium = iconMedium,
        _iconLarge = iconLarge,
        _iconXLarge = iconXLarge,
        _borderWidth = borderWidth,
        _borderWidthThick = borderWidthThick;

  /// The base values behind [AppSizes].
  const SystematicSizes.standard()
      : _space = 8,
        _spaceHalf = 4,
        _radiusTiny = 2,
        _radiusSmall = 8,
        _radiusMedium = 16,
        _radiusLarge = 24,
        _iconTiny = 8,
        _iconSmall = 16,
        _iconMedium = 24,
        _iconLarge = 32,
        _iconXLarge = 48,
        _borderWidth = 1,
        _borderWidthThick = 2;

  /// The nearest sizes in the theme, or [SystematicSizes.standard] if there are
  /// none.
  static SystematicSizes of(BuildContext context) =>
      Theme.of(context).extension<SystematicSizes>() ??
      const SystematicSizes.standard();

  final double _space;
  final double _spaceHalf;
  final double _radiusTiny;
  final double _radiusSmall;
  final double _radiusMedium;
  final double _radiusLarge;
  final double _iconTiny;
  final double _iconSmall;
  final double _iconMedium;
  final double _iconLarge;
  final double _iconXLarge;
  final double _borderWidth;
  final double _borderWidthThick;

  double _scaled(double base) => UiScaler.instance.px(base);

  /// The base spacing unit (8 before scaling), scaled for the screen.
  double get space => _scaled(_space);

  /// Half the base unit (4 before scaling).
  double get spaceHalf => _scaled(_spaceHalf);
  double get radiusTiny => _scaled(_radiusTiny);
  double get radiusSmall => _scaled(_radiusSmall);
  double get radiusMedium => _scaled(_radiusMedium);
  double get radiusLarge => _scaled(_radiusLarge);

  // Icons scale like text (sp), so they stay in proportion to labels.
  double get iconTiny => UiScaler.instance.sp(_iconTiny);
  double get iconSmall => UiScaler.instance.sp(_iconSmall);
  double get iconMedium => UiScaler.instance.sp(_iconMedium);
  double get iconLarge => UiScaler.instance.sp(_iconLarge);
  double get iconXLarge => UiScaler.instance.sp(_iconXLarge);

  /// Hairline stroke (1 before scaling).
  double get borderWidth => _scaled(_borderWidth);

  /// Emphasis stroke (2 before scaling).
  double get borderWidthThick => _scaled(_borderWidthThick);

  // Control heights are multiples of the spacing unit, so they follow it:
  // changing [space] resizes buttons and bars with it.
  double get buttonHeight => space * 6;
  double get inputHeight => space * 7;
  double get appBarHeight => space * 7;

  @override
  SystematicSizes copyWith({
    double? space,
    double? spaceHalf,
    double? radiusTiny,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? iconTiny,
    double? iconSmall,
    double? iconMedium,
    double? iconLarge,
    double? iconXLarge,
    double? borderWidth,
    double? borderWidthThick,
  }) =>
      SystematicSizes(
        space: space ?? _space,
        spaceHalf: spaceHalf ?? _spaceHalf,
        radiusTiny: radiusTiny ?? _radiusTiny,
        radiusSmall: radiusSmall ?? _radiusSmall,
        radiusMedium: radiusMedium ?? _radiusMedium,
        radiusLarge: radiusLarge ?? _radiusLarge,
        iconTiny: iconTiny ?? _iconTiny,
        iconSmall: iconSmall ?? _iconSmall,
        iconMedium: iconMedium ?? _iconMedium,
        iconLarge: iconLarge ?? _iconLarge,
        iconXLarge: iconXLarge ?? _iconXLarge,
        borderWidth: borderWidth ?? _borderWidth,
        borderWidthThick: borderWidthThick ?? _borderWidthThick,
      );

  @override
  SystematicSizes lerp(ThemeExtension<SystematicSizes>? other, double t) {
    if (other is! SystematicSizes) return this;
    double mix(double a, double b) => lerpDouble(a, b, t) ?? a;
    return SystematicSizes(
      space: mix(_space, other._space),
      spaceHalf: mix(_spaceHalf, other._spaceHalf),
      radiusTiny: mix(_radiusTiny, other._radiusTiny),
      radiusSmall: mix(_radiusSmall, other._radiusSmall),
      radiusMedium: mix(_radiusMedium, other._radiusMedium),
      radiusLarge: mix(_radiusLarge, other._radiusLarge),
      iconTiny: mix(_iconTiny, other._iconTiny),
      iconSmall: mix(_iconSmall, other._iconSmall),
      iconMedium: mix(_iconMedium, other._iconMedium),
      iconLarge: mix(_iconLarge, other._iconLarge),
      iconXLarge: mix(_iconXLarge, other._iconXLarge),
      borderWidth: mix(_borderWidth, other._borderWidth),
      borderWidthThick: mix(_borderWidthThick, other._borderWidthThick),
    );
  }
}

/// The preset paddings of [AppPadding], computed from a theme's sizes. Named
/// like [VSpace] and [HSpace]: read it as `context.padding`.
class PaddingSpace {
  const PaddingSpace(this._sizes);

  final SystematicSizes _sizes;

  double get _s => _sizes.space;

  EdgeInsets get allSingle => EdgeInsets.all(_s);
  EdgeInsets get allDouble => EdgeInsets.all(_s * 2);
  EdgeInsets get allTriple => EdgeInsets.all(_s * 3);

  EdgeInsets get horizontalSingle => EdgeInsets.symmetric(horizontal: _s);
  EdgeInsets get horizontalDouble => EdgeInsets.symmetric(horizontal: _s * 2);
  EdgeInsets get horizontalTriple => EdgeInsets.symmetric(horizontal: _s * 3);

  EdgeInsets get verticalSingle => EdgeInsets.symmetric(vertical: _s);
  EdgeInsets get verticalDouble => EdgeInsets.symmetric(vertical: _s * 2);
  EdgeInsets get verticalTriple => EdgeInsets.symmetric(vertical: _s * 3);
  EdgeInsets get verticalQuadruple => EdgeInsets.symmetric(vertical: _s * 4);

  EdgeInsets get page => EdgeInsets.all(_s * 2);
  EdgeInsets get pageHorizontal => EdgeInsets.symmetric(horizontal: _s * 2);
  EdgeInsets get card => EdgeInsets.all(_s * 2);
  EdgeInsets get listItem =>
      EdgeInsets.symmetric(vertical: _s, horizontal: _s * 2);
  EdgeInsets get inputContent =>
      EdgeInsets.symmetric(vertical: _s * 1.5, horizontal: _s * 2);
}

extension SystematicSizesContext on BuildContext {
  /// The spacing unit and radii for this part of the tree.
  SystematicSizes get sizes => SystematicSizes.of(this);

  /// Preset paddings that follow [sizes].
  PaddingSpace get padding => PaddingSpace(sizes);
}
