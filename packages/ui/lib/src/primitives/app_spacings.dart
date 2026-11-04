import 'package:flutter/material.dart';
import 'app_sizes.dart';
import 'systematic_sizes.dart';

/// Predefined, responsive EdgeInsets using the design system spacing.
class AppPadding {
  AppPadding._();

  // --- Generic Padding ---
  static EdgeInsets get allSingle => EdgeInsets.all(AppSizes.space);
  static EdgeInsets get allDouble => EdgeInsets.all(AppSizes.space * 2);
  static EdgeInsets get allTriple => EdgeInsets.all(AppSizes.space * 3);

  static EdgeInsets get horizontalSingle =>
      EdgeInsets.symmetric(horizontal: AppSizes.space);
  static EdgeInsets get horizontalDouble =>
      EdgeInsets.symmetric(horizontal: AppSizes.space * 2);
  static EdgeInsets get horizontalTriple =>
      EdgeInsets.symmetric(horizontal: AppSizes.space * 3);

  static EdgeInsets get verticalSingle =>
      EdgeInsets.symmetric(vertical: AppSizes.space);
  static EdgeInsets get verticalDouble =>
      EdgeInsets.symmetric(vertical: AppSizes.space * 2);
  static EdgeInsets get verticalTriple =>
      EdgeInsets.symmetric(vertical: AppSizes.space * 3);
  static EdgeInsets get verticalQuadruple =>
      EdgeInsets.symmetric(vertical: AppSizes.space * 4);

  // --- Semantic Padding ---
  static EdgeInsets get page => EdgeInsets.all(AppSizes.space * 2);
  static EdgeInsets get pageHorizontal =>
      EdgeInsets.symmetric(horizontal: AppSizes.space * 2);
  static EdgeInsets get card => EdgeInsets.all(AppSizes.space * 2);
  static EdgeInsets get listItem => EdgeInsets.symmetric(
        vertical: AppSizes.space,
        horizontal: AppSizes.space * 2,
      );
  static EdgeInsets get inputContent => EdgeInsets.symmetric(
        vertical: AppSizes.space * 1.5,
        horizontal: AppSizes.space * 2,
      );
}

/// Vertical spacer widget using design system spacing.
///
/// Each spacer is a multiple of the theme's base unit ([SystematicSizes.space])
/// and reads it when it builds, so changing the sizes in the theme re-spaces
/// every spacer under it.
class VSpace extends StatelessWidget {
  final double units;
  const VSpace._(this.units);

  static const VSpace x025 = VSpace._(0.25); // Tiny glue
  static const VSpace x05 = VSpace._(0.5);
  static const VSpace x1 = VSpace._(1);
  static const VSpace x2 = VSpace._(2);
  static const VSpace x3 = VSpace._(3);
  static const VSpace x4 = VSpace._(4);
  static const VSpace x5 = VSpace._(5);
  static const VSpace x6 = VSpace._(6);
  static const VSpace x8 = VSpace._(8);

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: units * SystematicSizes.of(context).space);
}

/// Horizontal spacer widget using design system spacing.
class HSpace extends StatelessWidget {
  final double units;
  const HSpace._(this.units);

  static const HSpace x025 = HSpace._(0.25);
  static const HSpace x05 = HSpace._(0.5);
  static const HSpace x1 = HSpace._(1);
  static const HSpace x2 = HSpace._(2);
  static const HSpace x3 = HSpace._(3);
  static const HSpace x4 = HSpace._(4);
  static const HSpace x5 = HSpace._(5);
  static const HSpace x6 = HSpace._(6);
  static const HSpace x8 = HSpace._(8);

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: units * SystematicSizes.of(context).space);
}
