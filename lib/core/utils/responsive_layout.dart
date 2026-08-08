import 'package:flutter/material.dart';

/// Breakpoints aligned with Material adaptive layout guidance.
abstract final class Breakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;
}

enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= Breakpoints.expanded) return ScreenSize.expanded;
  if (width >= Breakpoints.medium) return ScreenSize.medium;
  return ScreenSize.compact;
}

bool isCompact(BuildContext context) =>
    screenSizeOf(context) == ScreenSize.compact;

/// Constrains content width on phones/tablets for readable enterprise forms.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 440,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// Builds different layouts for compact vs wider screens.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  final Widget compact;
  final Widget? medium;
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    switch (screenSizeOf(context)) {
      case ScreenSize.expanded:
        return expanded ?? medium ?? compact;
      case ScreenSize.medium:
        return medium ?? compact;
      case ScreenSize.compact:
        return compact;
    }
  }
}
