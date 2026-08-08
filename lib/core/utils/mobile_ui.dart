import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/app_typography.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';

/// Shared mobile layout helpers for phone-first WMS screens (320–480dp wide).
abstract final class MobileUi {
  static const double minPhoneWidth = 320;
  static const double compactWidth = 360;
  static const double mediumWidth = 393;
  static const double largePhoneWidth = 430;
  static const double maxPhoneWidth = 480;
  static const double tabletWidth = 768;

  static const double bottomNavHeight = 70;
  static const double bottomNavIconSize = WmsIconSizes.bottomNav;
  static const double bottomNavLabelSize = 11;
  static const double expiryChartSize = 140;

  static bool isTablet(double width) => width >= tabletWidth;

  static bool isPhone(double width) => width < tabletWidth;

  static bool isNarrowPhone(double width) => width <= minPhoneWidth;

  static bool isCompactPhone(double width) => width <= compactWidth;

  /// Phone-first stacked dashboard (web parity, single column).
  static bool isPhoneStacked(double width) => width < largePhoneWidth;

  /// Two-column compact grids on phones (320–480dp).
  static bool isMobileGrid(double width) => width < 600;

  static const double dashboardSectionGap = 16;
  static const double dashboardScreenPadding = 16;
  static const double dashboardChartAspectRatio = 1.6;

  /// Responsive horizontal inset — tighter on 320dp devices.
  static double horizontalPadding(double width) {
    if (width <= minPhoneWidth) return AppSpacing.md;
    if (width <= compactWidth) return AppSpacing.lg;
    return dashboardScreenPadding;
  }

  static EdgeInsets screenHorizontalInsets(double width) =>
      EdgeInsets.symmetric(horizontal: horizontalPadding(width));

  static EdgeInsets screenHorizontalInsetsOf(BuildContext context) =>
      screenHorizontalInsets(MediaQuery.sizeOf(context).width);

  static int dashboardGridColumns(double width) {
    if (isPhoneStacked(width)) return 1;
    if (isTablet(width)) return 2;
    return 2;
  }

  static double chartAspectRatio(double width) =>
      isPhoneStacked(width) ? dashboardChartAspectRatio : 16 / 9;

  static int quickActionColumns(double width) =>
      isTablet(width) ? 4 : 3;

  static int kpiColumns(double width) =>
      isTablet(width) ? 4 : 2;

  static int gridColumns(double width, {int phone = 2, int tablet = 4}) =>
      isTablet(width) ? tablet : phone;

  static MediaQueryData clampMediaQuery(MediaQueryData data) {
    return data.copyWith(
      textScaler: data.textScaler.clamp(
        minScaleFactor: 0.95,
        maxScaleFactor: 1.2,
      ),
    );
  }

  static double headerGreetingSize(double width) {
    if (width <= compactWidth) return 18;
    if (width <= mediumWidth) return 20;
    return 22;
  }

  static double headerSubtitleSize(double width) =>
      AppTypography.pageSubtitleSize;

  static double headerBottomGap(double width) =>
      width <= compactWidth ? 6.0 : 10.0;

  static double profileAvatarRadius(double width) =>
      width <= compactWidth ? 24.0 : 30.0;

  static double shellAppBarHeight(double width) =>
      width <= compactWidth ? 48.0 : 56.0;

  static TextStyle screenHeroTitle(BuildContext context, double width) =>
      WmsDesignTokens.pageTitle(context);

  static EdgeInsets screenHeroPadding(double width) {
    final horizontal = horizontalPadding(width);
    final vertical = width <= compactWidth ? 12.0 : 16.0;
    return EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical);
  }

  /// Minimum KPI tile height for 2-column phone grids (320–480dp).
  static const double kpiGridMainAxisExtent = 148;

  /// Taller KPI rows when cards include subtitle and/or badge.
  static const double kpiGridMainAxisExtentDetailed = 162;

  /// Horizontal KPI chip strip (catalog screens).
  static const double horizontalKpiStripHeight = 116;

  /// Responsive KPI row height — taller on narrow screens to prevent overflow.
  static double kpiGridMainAxisExtentFor(double width) {
    if (width <= minPhoneWidth) return 156;
    if (width <= compactWidth) return 152;
    return kpiGridMainAxisExtent;
  }

  /// Stat tile columns inside product cards — 2 on narrow, 3 otherwise.
  static int statTileColumns(double width) => width < 340 ? 2 : 3;

  /// Two-column KPI grid delegate — fixed row height prevents bottom overflow.
  static SliverGridDelegateWithFixedCrossAxisCount phoneKpiGridDelegate({
    int crossAxisCount = 2,
    double spacing = dashboardSectionGap,
    double mainAxisExtent = kpiGridMainAxisExtent,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      mainAxisExtent: mainAxisExtent,
    );
  }

  /// KPI grid row height tuned for 2-column phone layout.
  static double kpiTileHeight(double width) => kpiGridMainAxisExtentFor(width);

  /// Quick action tile height for 3-column phone grid.
  static double quickActionTileHeight(double width) =>
      width <= compactWidth ? 118 : 124;
}
