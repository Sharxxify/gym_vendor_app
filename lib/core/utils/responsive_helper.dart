import 'package:flutter/material.dart';

class ResponsiveHelper {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double textScaleFactor;
  static late EdgeInsets padding;
  static late EdgeInsets viewInsets;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    textScaleFactor = _mediaQueryData.textScaleFactor;
    padding = _mediaQueryData.padding;
    viewInsets = _mediaQueryData.viewInsets;

    safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;
  }

  // Width helpers
  static double w(double percentage) => blockSizeHorizontal * percentage;
  static double sw(double percentage) => safeBlockHorizontal * percentage;

  // Height helpers
  static double h(double percentage) => blockSizeVertical * percentage;
  static double sh(double percentage) => safeBlockVertical * percentage;

  // Font size helper (responsive to screen width)
  static double sp(double size) {
    return size * (screenWidth / 375); // 375 is base width (iPhone 8)
  }

  // Check device type
  static bool get isMobile => screenWidth < 600;
  static bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  static bool get isDesktop => screenWidth >= 1024;

  // Check orientation
  static bool get isPortrait => screenHeight > screenWidth;
  static bool get isLandscape => screenWidth > screenHeight;

  // Get adaptive value based on screen size
  static T adaptive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

extension ResponsiveExtension on num {
  double get w => ResponsiveHelper.w(toDouble());
  double get h => ResponsiveHelper.h(toDouble());
  double get sw => ResponsiveHelper.sw(toDouble());
  double get sh => ResponsiveHelper.sh(toDouble());
  double get sp => ResponsiveHelper.sp(toDouble());
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveHelper helper) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    return builder(context, ResponsiveHelper());
  }
}
