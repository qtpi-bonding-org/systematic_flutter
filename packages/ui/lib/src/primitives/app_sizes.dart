import 'ui_scaler.dart';

/// Design tokens for all scalable dimensions.
/// Single source of truth for sizes, spacing, radii, and typography scale.
class AppSizes {
  AppSizes._();

  // --- Base Spacing Unit (8dp grid) ---
  static double get space => UiScaler.instance.px(8.0);
  static double get spaceHalf => UiScaler.instance.px(4.0);

  // --- Font Sizes (Semantic) ---
  static double get fontMini => UiScaler.instance.sp(12.0);
  static double get fontSmall => UiScaler.instance.sp(14.0);
  static double get fontStandard => UiScaler.instance.sp(16.0);
  static double get fontBig => UiScaler.instance.sp(18.0);
  static double get fontLarge => UiScaler.instance.sp(24.0);
  static double get fontMassive => UiScaler.instance.sp(36.0);

  // --- Legacy Sizes (Keep for Dimensions) ---
  static double get size12 => UiScaler.instance.sp(12.0);
  static double get size14 => UiScaler.instance.sp(14.0);
  static double get size16 => UiScaler.instance.sp(16.0);
  static double get size18 => UiScaler.instance.sp(18.0);
  static double get size20 => UiScaler.instance.sp(20.0);
  static double get size22 => UiScaler.instance.sp(22.0);
  static double get size24 => UiScaler.instance.sp(24.0);
  static double get size28 => UiScaler.instance.sp(28.0);
  static double get size32 => UiScaler.instance.sp(32.0);
  static double get size36 => UiScaler.instance.sp(36.0);
  static double get size38 => UiScaler.instance.sp(38.0);
  static double get size44 => UiScaler.instance.sp(44.0);
  static double get size48 => UiScaler.instance.sp(48.0);
  static double get size56 => UiScaler.instance.sp(56.0);

  // --- Icon Sizes ---
  static double get iconTiny => UiScaler.instance.sp(8.0);
  static double get iconSmall => UiScaler.instance.sp(16.0);
  static double get iconMedium => UiScaler.instance.sp(24.0);
  static double get iconLarge => UiScaler.instance.sp(32.0);
  static double get iconXLarge => UiScaler.instance.sp(48.0);

  // --- Radii ---
  static double get radiusTiny => space * 0.25; // 2
  static double get radiusSmall => space; // 8
  static double get radiusMedium => space * 2; // 16
  static double get radiusLarge => space * 3; // 24

  // --- Component Dimensions ---
  static double get buttonHeight => space * 6; // 48
  static double get inputHeight => space * 7; // 56
  static double get appBarHeight => space * 7; // 56
  static double get bottomBarHeight => space * 10; // 80

  // --- Border ---
  static double get borderWidth => UiScaler.instance.px(1.0);
  static double get borderWidthThick => UiScaler.instance.px(2.0);

  // --- Bioluminescent Opacity Scale ---
  /// Primary, focused, fully active
  static const double opacityFull = 1.0;

  /// Hover, secondary emphasis
  static const double opacityHover = 0.7;

  /// Inactive chrome, non-text dividers (NOT for dim text — contrast too low)
  static const double opacityInactive = 0.4;

  /// Disabled (Material standard 0.38, quanitya-validated)
  static const double opacityDisabled = 0.38;

  /// Ghost fill for input fields at rest (barely visible cyan hint)
  static const double opacityGhost = 0.06;

  // --- Content Sizes ---
  static double get qrCodeSize => UiScaler.instance.px(250.0);
}
