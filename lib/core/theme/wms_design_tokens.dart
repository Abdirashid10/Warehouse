import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_typography.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';

/// Unified enterprise design tokens for all WMS screens.
abstract final class WmsDesignTokens {
  static const double sectionGap = AppSpacing.sectionGap;
  static const double screenPadding = AppSpacing.screenPadding;
  static const double cardRadius = AppSpacing.radiusLg;
  static const double chipRadius = AppSpacing.radiusSm;
  static const double minTouchTarget = AppSpacing.buttonHeight;
  static const double minReadableFontSize = AppTypography.minFontSize;
  static const double sectionAccentBarWidth = 4.0;
  static const double sectionAccentBarHeight = 22.0;
  static const double kpiIconSize = WmsIconSizes.kpi;
  static const double iconCardPadding = WmsIconSizes.iconCardPadding;
  static const double kpiLabelFontSize = AppTypography.descriptionSize;
  static const double chartAxisFontSize = AppTypography.captionSize;

  static const double compactPhoneWidth = 360;
  static const double mediumPhoneWidth = 393;
  static const double largePhoneWidth = 412;
  static const double tabletWidth = 768;
  static const double kpiCardMinHeight = 110;
  static const double analyticsCardMinHeight = 260;
  static const double taskCardMinHeight = 120;
  static const double warehouseCardMinHeight = 140;

  static int kpiColumns(double width) => width >= tabletWidth ? 4 : 2;

  static double kpiTileWidth(double maxWidth, double width) {
    final columns = kpiColumns(width);
    const gap = AppSpacing.sm;
    return (maxWidth - gap * (columns - 1)) / columns;
  }

  /// KPI / card numbers — fixed global scale (26px Poppins bold).
  static double kpiNumberSize(double width) => AppTypography.cardNumberSize;

  static EdgeInsets screenHorizontalPadding(double width) {
    if (width >= tabletWidth) {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.xxl);
    }
    return const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding);
  }

  static TextStyle _withPrimaryText(BuildContext context, TextStyle base) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.brightness == Brightness.light
        ? AppTypographyColors.primaryText
        : scheme.onSurface;
    return base.copyWith(color: color);
  }

  static TextStyle _withSecondaryText(BuildContext context, TextStyle base) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.brightness == Brightness.light
        ? AppTypographyColors.secondaryText
        : scheme.onSurfaceVariant;
    return base.copyWith(color: color);
  }

  static TextStyle pageTitle(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.pageTitle);

  static TextStyle pageSubtitle(BuildContext context) =>
      _withSecondaryText(context, AppTextStyles.pageSubtitle);

  static TextStyle sectionTitle(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.sectionTitle);

  static TextStyle cardTitle(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.cardTitle);

  static TextStyle cardNumber(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.cardNumber);

  static TextStyle kpiValue(BuildContext context, {double? width}) =>
      cardNumber(context);

  static TextStyle metricValue(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.cardNumber.copyWith(fontSize: 20));

  static TextStyle kpiLabel(BuildContext context) =>
      _withSecondaryText(
        context,
        AppTextStyles.description.copyWith(fontWeight: FontWeight.w600),
      );

  static TextStyle body(BuildContext context) =>
      _withPrimaryText(
        context,
        Theme.of(context).textTheme.bodyMedium ?? AppTextStyles.body,
      );

  static TextStyle bodyLarge(BuildContext context) => body(context);

  static TextStyle description(BuildContext context) =>
      _withSecondaryText(context, AppTextStyles.description);

  static TextStyle supporting(BuildContext context) =>
      _withSecondaryText(context, AppTextStyles.caption);

  static TextStyle supportingDense(BuildContext context) => supporting(context);

  static TextStyle caption(BuildContext context) =>
      _withSecondaryText(context, AppTextStyles.caption);

  static TextStyle legend(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.legend);

  static TextStyle userName(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.userName);

  static TextStyle email(BuildContext context) =>
      _withSecondaryText(context, AppTextStyles.email);

  static TextStyle badge(BuildContext context) =>
      _withSecondaryText(
        context,
        AppTextStyles.badge.copyWith(fontWeight: FontWeight.w600),
      );

  static TextStyle metadata(BuildContext context) =>
      _withSecondaryText(context, AppTextStyles.metadata);

  static TextStyle formLabel(BuildContext context) =>
      _withSecondaryText(
        context,
        AppTextStyles.formLabel.copyWith(fontWeight: FontWeight.w500),
      );

  static TextStyle inputText(BuildContext context) =>
      _withPrimaryText(
        context,
        Theme.of(context).textTheme.bodyMedium ?? AppTextStyles.inputText,
      );

  static TextStyle drawerMenuItem(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.drawerMenuItem);

  static TextStyle drawerMenuItemActive(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.drawerMenuItemActive);

  static TextStyle drawerAppName(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.drawerAppName);

  static TextStyle drawerHeaderSubtitle(BuildContext context) =>
      _withSecondaryText(context, AppTextStyles.drawerHeaderSubtitle);

  static TextStyle drawerSectionTitle(BuildContext context) =>
      _withPrimaryText(context, AppTextStyles.drawerSectionTitle);

  static TextStyle buttonLabel(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge ?? AppTextStyles.button;

  static TextStyle chartAxis(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.brightness == Brightness.light
        ? AppTypographyColors.secondaryText
        : scheme.onSurfaceVariant;
    return AppTextStyles.caption.copyWith(color: color);
  }

  /// Operational alert count — bold semantic color.
  static TextStyle operationalAlertCount(
    BuildContext context, {
    required Color color,
    double fontSize = 24,
  }) =>
      AppTextStyles.cardNumber.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 1.1,
      );

  /// Operational alert label — semibold semantic color.
  static TextStyle operationalAlertLabel(
    BuildContext context, {
    required Color color,
  }) =>
      AppTextStyles.description.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle bottomNavLabel(
    BuildContext context, {
    required bool selected,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final inactive = scheme.brightness == Brightness.light
        ? AppTypographyColors.secondaryText
        : scheme.onSurfaceVariant;
    return AppTextStyles.navigationLabel.copyWith(
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      color: color ?? (selected ? scheme.primary : inactive),
    );
  }
}
