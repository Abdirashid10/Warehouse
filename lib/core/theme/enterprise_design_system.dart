import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme_colors.dart';
import 'package:logisticsmobile/core/theme/app_typography.dart';

/// Global enterprise design system for Logistics WMS Mobile.
///
/// All UI must consume tokens via [Theme.of] / [WmsDesignTokens] — never hard-code.
abstract final class EnterpriseDesignSystem {
  static const headingFontFamily = AppTypography.headingFontFamily;
  static const bodyFontFamily = AppTypography.bodyFontFamily;
  static const fontFamily = AppTypography.bodyFontFamily;

  static const pageTitleSize = AppTypography.pageTitleSize;
  static const sectionTitleSize = AppTypography.sectionTitleSize;
  static const cardTitleSize = AppTypography.cardTitleSize;
  static const kpiNumberSize = AppTypography.cardNumberSize;
  static const bodySize = AppTypography.bodySize;
  static const labelSize = AppTypography.captionSize;
  static const navLabelSize = AppTypography.navLabelSize;
  static const buttonTextSize = AppTypography.buttonTextSize;
  static const minFontSize = AppTypography.minFontSize;

  static const pagePadding = AppSpacing.screenPadding;
  static const cardPadding = AppSpacing.cardPadding;
  static const cardRadius = AppSpacing.radiusLg;
  static const buttonRadius = AppSpacing.radiusButton;
  static const sectionGap = AppSpacing.sectionGap;
  static const cardGap = AppSpacing.cardGap;

  static const kpiCardMinHeight = 110.0;
  static const analyticsCardMinHeight = 260.0;
  static const taskCardMinHeight = 120.0;
  static const warehouseCardMinHeight = 140.0;

  static const phoneMinWidth = 360.0;
  static const phoneMaxWidth = 430.0;
  static const tabletMinWidth = 768.0;

  static const lightBackground = AppThemeColors.lightBackground;
  static const lightSurface = AppThemeColors.lightSurface;
  static const lightPrimary = AppThemeColors.lightPrimary;
  static const lightTextPrimary = AppThemeColors.lightTextPrimary;
  static const lightTextSecondary = AppThemeColors.lightTextSecondary;
  static const lightBorder = AppThemeColors.lightBorder;

  static const darkBackground = AppThemeColors.darkBackground;
  static const darkSurface = AppThemeColors.darkSurface;
  static const darkCard = AppThemeColors.darkCard;
  static const darkPrimary = AppThemeColors.darkPrimary;
  static const darkTextPrimary = AppThemeColors.darkTextPrimary;
  static const darkTextSecondary = AppThemeColors.darkTextSecondary;
  static const darkBorder = AppThemeColors.darkBorder;

  static const success = AppThemeColors.success;
  static const warning = AppThemeColors.warning;
  static const danger = AppThemeColors.danger;
}
