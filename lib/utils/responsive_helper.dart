import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => screenWidth(context) < 600;

  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= 600 && screenWidth(context) < 1024;

  static bool isDesktop(BuildContext context) => screenWidth(context) >= 1024;

  static double responsiveValue(
    BuildContext context, {
    required double base,
    double minScale = 0.7,
    double maxScale = 1.2,
  }) {
    if (isMobile(context)) {
      return base * minScale;
    } else if (isTablet(context)) {
      return base;
    } else {
      return base * maxScale;
    }
  }

  static EdgeInsets responsivePadding(BuildContext context) {
    final value = responsiveValue(context, base: 24);
    return EdgeInsets.all(value);
  }

  static EdgeInsets responsiveMargin(BuildContext context) {
    final value = responsiveValue(context, base: 12);
    return EdgeInsets.all(value);
  }

  static double titleFontSize(BuildContext context) =>
      responsiveValue(context, base: 22);

  static double bodyFontSize(BuildContext context) =>
      responsiveValue(context, base: 16);

  static double containerWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isMobile(context)) {
      return width * 0.9;
    } else if (isTablet(context)) {
      return width * 0.7;
    } else {
      return responsiveValue(context, base: 500);
    }
  }

  static double animationSize(BuildContext context) =>
      responsiveValue(context, base: 300);

  static int gridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }
}
