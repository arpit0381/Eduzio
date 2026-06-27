import 'package:flutter/material.dart';
import '../../core/constants/sizes.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Check if current screen is Mobile (< 600)
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppSizes.maxMobileWidth;

  /// Check if current screen is Tablet (600 <= width <= 1024)
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppSizes.maxMobileWidth &&
      MediaQuery.sizeOf(context).width <= AppSizes.maxTabletWidth;

  /// Check if current screen is Desktop (> 1024)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > AppSizes.maxTabletWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > AppSizes.maxTabletWidth) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= AppSizes.maxMobileWidth) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
