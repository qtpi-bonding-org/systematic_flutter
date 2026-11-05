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
/// The named icon sizes, as multiples of the icon unit (4 before scaling):
/// `x4` is 16, `x6` is 24. Mirrors the spacing scale ([VSpace.x1] and so on).
enum IconStep {
  x2(2),
  x3(3),
  x4(4),
  x5(5),
  x6(6),
  x7(7),
  x8(8),
  x12(12),
  x14(14);

  const IconStep(this.units);
  final double units;
}

@immutable
class SystematicSizes extends ThemeExtension<SystematicSizes> {
  const SystematicSizes({
    required double space,
    required double spaceHalf,
    required double radiusTiny,
    required double radiusSmall,
    required double radiusMedium,
    required double radiusLarge,
    double iconUnit = 4,
    double borderWidth = 1,
    double borderWidthThick = 2,
  })  : _space = space,
        _spaceHalf = spaceHalf,
        _radiusTiny = radiusTiny,
        _radiusSmall = radiusSmall,
        _radiusMedium = radiusMedium,
        _radiusLarge = radiusLarge,
        _iconUnit = iconUnit,
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
        _iconUnit = 4,
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
  final double _iconUnit;
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

  /// An icon size: [step] times the icon unit (4 before scaling), scaled like
  /// text so icons stay in proportion to labels. Like spacing, a caller picks
  /// a named step and never writes a pixel count.
  double icon(IconStep step) => UiScaler.instance.sp(_iconUnit * step.units);

  double get iconTiny => icon(IconStep.x2); // 8
  double get iconXSmall => icon(IconStep.x3); // 12
  double get iconSmall => icon(IconStep.x4); // 16
  double get iconMedium => icon(IconStep.x6); // 24
  double get iconLarge => icon(IconStep.x8); // 32
  double get iconXLarge => icon(IconStep.x12); // 48

  /// Hairline stroke (1 before scaling).
  double get borderWidth => _scaled(_borderWidth);

  /// Emphasis stroke (2 before scaling).
  double get borderWidthThick => _scaled(_borderWidthThick);

  /// The icon theme for `ThemeData.iconTheme`: icons grow with the system text
  /// size, so a label and its icon stay in proportion at large text.
  IconThemeData get iconTheme =>
      IconThemeData(size: iconMedium, applyTextScaling: true);

  // Control heights are multiples of the spacing unit, so they follow it:
  // changing [space] resizes buttons and bars with it.
  double get buttonHeight => space * 6;
  double get inputHeight => space * 7;
  double get appBarHeight => space * 7;

  /// A compact bar: the tab rail row, the top bar, a panel's tab row.
  double get barHeight => space * 5;

  @override
  SystematicSizes copyWith({
    double? space,
    double? spaceHalf,
    double? radiusTiny,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? iconUnit,
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
        iconUnit: iconUnit ?? _iconUnit,
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
      iconUnit: mix(_iconUnit, other._iconUnit),
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
