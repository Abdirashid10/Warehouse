import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_theme_colors.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';

/// Legacy dark palette aliases — prefer [WmsUiColors.of] for theme-aware usage.
abstract final class WmsDarkColors {
  static const background = AppThemeColors.darkBackground;
  static const surface = AppThemeColors.darkSurface;
  static const surfaceElevated = AppThemeColors.darkSurfaceVariant;
  static const border = AppThemeColors.darkBorder;
  static const textPrimary = AppThemeColors.darkTextPrimary;
  static const textSecondary = AppThemeColors.darkTextSecondary;
  static const textTertiary = AppThemeColors.darkTextTertiary;
  static const primary = AppThemeColors.darkPrimary;
  static const primaryMuted = Color(0xFF1E3A8A);
  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFF87171);
  static const outbound = Color(0xFFFB923C);
  static const expired = Color(0xFFA78BFA);
  static const expiredMuted = Color(0xFF4C1D95);
}

/// Deprecated — global [ThemeData] from [AppTheme] handles light/dark modes.
abstract final class WmsDarkTheme {
  static Widget wrapIfDark(BuildContext context, Widget child) => child;

  static Widget wrap(BuildContext context, Widget child) => child;

  static TextStyle pageTitle(BuildContext context) =>
      WmsDesignTokens.pageTitle(context).copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      );

  static TextStyle subtitle(BuildContext context) =>
      WmsDesignTokens.supporting(context).copyWith(
        color: context.wms.textSecondary,
      );

  static TextStyle sectionLabel(BuildContext context) =>
      WmsDesignTokens.kpiLabel(context).copyWith(
        color: context.wms.textTertiary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      );
}
