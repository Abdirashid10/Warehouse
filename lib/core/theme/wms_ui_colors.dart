import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme_colors.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';

/// Theme-adaptive semantic colors for all WMS modules.
///
/// Prefer this over static [AppColors] in UI code.
class WmsUiColors {
  const WmsUiColors._(this._wms, this._scheme, this._isDark);

  factory WmsUiColors.of(BuildContext context) {
    return WmsUiColors._(
      context.wms,
      Theme.of(context).colorScheme,
      Theme.of(context).brightness == Brightness.dark,
    );
  }

  final WmsThemeExtension _wms;
  final ColorScheme _scheme;
  final bool _isDark;

  bool get isDark => _isDark;

  Color get background =>
      _isDark ? AppThemeColors.darkBackground : AppThemeColors.lightBackground;

  Color get surface =>
      _isDark ? AppThemeColors.darkSurface : AppThemeColors.lightSurface;

  Color get surfaceElevated =>
      _isDark ? AppThemeColors.darkSurfaceVariant : AppThemeColors.lightSurfaceVariant;

  Color get border =>
      _isDark ? AppThemeColors.darkBorder : AppThemeColors.lightBorder;

  Color get textPrimary =>
      _isDark ? _scheme.onSurface : AppThemeColors.lightTextPrimary;

  Color get textSecondary =>
      _isDark ? _scheme.onSurfaceVariant : _wms.textSecondary;

  Color get textTertiary =>
      _isDark ? AppThemeColors.darkTextTertiary : _wms.textTertiary;

  Color get primary => _scheme.primary;

  Color get primaryMuted => _wms.primaryLight;

  Color get onPrimary => _scheme.onPrimary;

  Color get onGradient => AppThemeColors.onGradient;

  Color get success => _wms.success;

  Color get successMuted => _wms.successLight;

  Color get warning => _wms.warning;

  Color get warningMuted => _wms.warningLight;

  Color get error => _wms.error;

  Color get errorMuted => _wms.errorLight;

  Color get info => _wms.info;

  Color get infoMuted => _wms.infoLight;

  Color get accent => _isDark ? const Color(0xFF38BDF8) : AppColors.accent;

  Color get accentMuted => _wms.accentLight;

  Color get tasks => _wms.tasks;

  Color get tasksMuted => _wms.tasksLight;

  Color get outbound =>
      _isDark ? const Color(0xFFFB923C) : AppColors.outbound;

  Color get expired =>
      _isDark ? const Color(0xFFA78BFA) : AppColors.expired;

  Color get expiredMuted =>
      _isDark ? const Color(0xFF4C1D95) : AppColors.expiredLight;

  Color get processing =>
      _isDark ? const Color(0xFF60A5FA) : AppColors.processing;

  Color get processingMuted =>
      _isDark ? const Color(0xFF1E3A8A) : AppColors.processingLight;

  Color get cardBackground => _wms.cardBackground;

  LinearGradient get brandGradient => _wms.brandGradient;

  LinearGradient get splashGradient => _wms.splashGradient;

  List<BoxShadow> get cardShadow => _wms.cardShadow;

  Color get chartGrid => border.withValues(alpha: _isDark ? 0.55 : 1.0);

  Color get chartAxisLabel => textSecondary;

  Color get chartLabel => textPrimary;

  Color get chartTooltipBackground =>
      _isDark ? AppThemeColors.darkSurfaceVariant : AppThemeColors.lightSurface;

  Color get iconPrimary => textPrimary;

  Color get iconSecondary => textSecondary;

  Color get divider => _wms.divider;

  /// Muted surface for badges, chips, and icon backgrounds.
  Color get mutedSurface => surfaceElevated;

  /// Light palette for static helpers when [BuildContext] is unavailable.
  factory WmsUiColors.lightPalette() {
    return WmsUiColors._(
      WmsThemeExtension.light,
      const ColorScheme(
        brightness: Brightness.light,
        primary: AppThemeColors.lightPrimary,
        onPrimary: AppThemeColors.onPrimaryButton,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppThemeColors.lightSurface,
        onSurface: AppThemeColors.lightTextPrimary,
        onSurfaceVariant: AppThemeColors.lightTextSecondary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppThemeColors.lightBorder,
      ),
      false,
    );
  }

  /// Dark palette for static helpers when [BuildContext] is unavailable.
  factory WmsUiColors.darkPalette() {
    return WmsUiColors._(
      WmsThemeExtension.dark,
      ColorScheme.fromSeed(
        seedColor: AppThemeColors.darkPrimary,
        brightness: Brightness.dark,
      ),
      true,
    );
  }
}

/// Shared component styling — radius, shadows, spacing.
abstract final class WmsComponentStyles {
  static BorderRadius get cardRadius =>
      BorderRadius.circular(AppSpacing.radiusLg);

  static BorderRadius get chipRadius =>
      BorderRadius.circular(AppSpacing.radiusSm);

  static BorderRadius get buttonRadius =>
      BorderRadius.circular(AppSpacing.radiusMd);

  static BorderRadius get inputRadius =>
      BorderRadius.circular(AppSpacing.radiusMd);

  static EdgeInsets get cardPadding =>
      const EdgeInsets.all(AppSpacing.cardPadding);

  static EdgeInsets get screenPadding =>
      const EdgeInsets.all(AppSpacing.screenPadding);

  static BoxDecoration cardDecoration(WmsUiColors colors, {bool elevated = false}) {
    return BoxDecoration(
      color: colors.cardBackground,
      borderRadius: cardRadius,
      border: Border.all(color: colors.border.withValues(alpha: 0.65)),
      boxShadow: elevated ? colors.cardShadow : null,
    );
  }

  static BoxDecoration badgeDecoration({
    required Color foreground,
    required Color background,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: chipRadius,
      border: Border.all(color: foreground.withValues(alpha: 0.22)),
    );
  }
}
