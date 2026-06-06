import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

enum ScreenSize { mobile, tablet, desktop }

class Responsive {
  static double width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static ScreenSize screenSize(BuildContext context) {
    final w = width(context);
    if (w >= AppBreakpoints.desktop) return ScreenSize.desktop;
    if (w >= AppBreakpoints.tablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  static bool isMobile(BuildContext context) =>
      width(context) < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final w = width(context);
    return w >= AppBreakpoints.mobile && w < AppBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) =>
      width(context) >= AppBreakpoints.desktop;

  static bool useSideNav(BuildContext context) =>
      width(context) >= AppBreakpoints.tablet;

  static double contentMaxWidth(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.desktop:
        return 1100;
      case ScreenSize.tablet:
        return 860;
      case ScreenSize.mobile:
        return double.infinity;
    }
  }

  static double formMaxWidth(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.desktop:
        return 520;
      case ScreenSize.tablet:
        return 480;
      case ScreenSize.mobile:
        return double.infinity;
    }
  }

  static EdgeInsets pagePadding(BuildContext context) {
    switch (screenSize(context)) {
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 28);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
      case ScreenSize.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
    }
  }

  static int gridColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 4}) {
    switch (screenSize(context)) {
      case ScreenSize.desktop:
        return desktop;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.mobile:
        return mobile;
    }
  }

  static T value<T>(BuildContext context, {required T mobile, required T tablet, required T desktop}) {
    switch (screenSize(context)) {
      case ScreenSize.desktop:
        return desktop;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.mobile:
        return mobile;
    }
  }
}

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final bool center;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? Responsive.pagePadding(context),
      child: child,
    );

    final constrained = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? Responsive.contentMaxWidth(context),
      ),
      child: content,
    );

    if (!center) return constrained;

    return Align(
      alignment: Alignment.topCenter,
      child: constrained,
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize size) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive.screenSize(context));
  }
}
