import 'package:flutter/material.dart';
import 'app_sizes.dart';

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
class VSpace extends StatelessWidget {
  final double height;
  const VSpace._(this.height);

  static VSpace get x025 => VSpace._(AppSizes.space * 0.25); // 2px (Tiny glue)
  static VSpace get x05 => VSpace._(AppSizes.space * 0.5);
  static VSpace get x1 => VSpace._(AppSizes.space);
  static VSpace get x2 => VSpace._(AppSizes.space * 2);
  static VSpace get x3 => VSpace._(AppSizes.space * 3);
  static VSpace get x4 => VSpace._(AppSizes.space * 4);
  static VSpace get x5 => VSpace._(AppSizes.space * 5);
  static VSpace get x6 => VSpace._(AppSizes.space * 6);
  static VSpace get x8 => VSpace._(AppSizes.space * 8);

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

/// Horizontal spacer widget using design system spacing.
class HSpace extends StatelessWidget {
  final double width;
  const HSpace._(this.width);

  static HSpace get x025 => HSpace._(AppSizes.space * 0.25);
  static HSpace get x05 => HSpace._(AppSizes.space * 0.5);
  static HSpace get x1 => HSpace._(AppSizes.space);
  static HSpace get x2 => HSpace._(AppSizes.space * 2);
  static HSpace get x3 => HSpace._(AppSizes.space * 3);
  static HSpace get x4 => HSpace._(AppSizes.space * 4);
  static HSpace get x5 => HSpace._(AppSizes.space * 5);
  static HSpace get x6 => HSpace._(AppSizes.space * 6);
  static HSpace get x8 => HSpace._(AppSizes.space * 8);

  @override
  Widget build(BuildContext context) => SizedBox(width: width);
}
