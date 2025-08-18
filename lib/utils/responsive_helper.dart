import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isMobile(BuildContext context) {
    return screenWidth(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= 600 && screenWidth(context) < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= 1024;
  }

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  // Responsive margin
  static EdgeInsets responsiveMargin(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(8);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  static double titleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 20;
    } else if (isTablet(context)) {
      return 24;
    } else {
      return 28;
    }
  }

  static double bodyFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 14;
    } else if (isTablet(context)) {
      return 16;
    } else {
      return 18;
    }
  }

  static double containerWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isMobile(context)) {
      return width * 0.9;
    } else if (isTablet(context)) {
      return width * 0.7;
    } else {
      return 600;
    }
  }

  static double animationSize(BuildContext context) {
    if (isMobile(context)) {
      return screenWidth(context) * 0.6;
    } else if (isTablet(context)) {
      return 350;
    } else {
      return 400;
    }
  }

  static int gridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }
}
