import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 1024;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1050;
    if (isTablet(context)) return 750;
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  static double heroHeaderPaddingTop(BuildContext context) {
    if (isMobile(context)) return 48;
    return 60;
  }
}
