import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_theme_colors.dart';

/// Semantic colors that adapt to light and dark themes.
@immutable
class WmsThemeExtension extends ThemeExtension<WmsThemeExtension> {
  const WmsThemeExtension({
    required this.cardBackground,
    required this.surfaceVariant,
    required this.border,
    required this.divider,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.primaryLight,
    required this.accentLight,
    required this.tasks,
    required this.tasksLight,
    required this.brandGradient,
    required this.splashGradient,
    required this.cardShadow,
  });

  static const light = WmsThemeExtension(
    cardBackground: AppThemeColors.lightSurface,
    surfaceVariant: AppThemeColors.lightSurfaceVariant,
    border: AppThemeColors.lightBorder,
    divider: AppColors.divider,
    textSecondary: AppThemeColors.lightTextSecondary,
    textTertiary: AppThemeColors.lightTextTertiary,
    success: AppColors.success,
    successLight: AppColors.successLight,
    warning: AppColors.warning,
    warningLight: AppColors.warningLight,
    error: AppColors.error,
    errorLight: AppColors.errorLight,
    info: AppColors.info,
    infoLight: AppColors.infoLight,
    primaryLight: AppColors.primaryLight,
    accentLight: AppColors.accentLight,
    tasks: AppColors.tasks,
    tasksLight: AppColors.tasksLight,
    brandGradient: AppColors.brandGradient,
    splashGradient: AppColors.splashGradient,
    cardShadow: [
      BoxShadow(
        color: Color(0x0D0F172A),
        blurRadius: 12,
        offset: Offset(0, 2),
      ),
      BoxShadow(
        color: Color(0x0A2563EB),
        blurRadius: 20,
        offset: Offset(0, 6),
      ),
    ],
  );

  static const dark = WmsThemeExtension(
    cardBackground: AppThemeColors.darkCard,
    surfaceVariant: AppThemeColors.darkSurfaceVariant,
    border: AppThemeColors.darkBorder,
    divider: AppThemeColors.darkSurfaceVariant,
    textSecondary: AppThemeColors.darkTextSecondary,
    textTertiary: AppThemeColors.darkTextTertiary,
    success: AppThemeColors.successDark,
    successLight: Color(0xFF14532D),
    warning: AppThemeColors.warning,
    warningLight: Color(0xFF78350F),
    error: AppThemeColors.danger,
    errorLight: Color(0xFF7F1D1D),
    info: Color(0xFF38BDF8),
    infoLight: Color(0xFF0C4A6E),
    primaryLight: Color(0xFF1E3A8A),
    accentLight: Color(0xFF0C4A6E),
    tasks: Color(0xFFA78BFA),
    tasksLight: Color(0xFF4C1D95),
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
      stops: [0.0, 0.5, 1.0],
    ),
    splashGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x30000000),
        blurRadius: 12,
        offset: Offset(0, 2),
      ),
      BoxShadow(
        color: Color(0x202563EB),
        blurRadius: 20,
        offset: Offset(0, 6),
      ),
    ],
  );

  final Color cardBackground;
  final Color surfaceVariant;
  final Color border;
  final Color divider;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color error;
  final Color errorLight;
  final Color info;
  final Color infoLight;
  final Color primaryLight;
  final Color accentLight;
  final Color tasks;
  final Color tasksLight;
  final LinearGradient brandGradient;
  final LinearGradient splashGradient;
  final List<BoxShadow> cardShadow;

  @override
  WmsThemeExtension copyWith({
    Color? cardBackground,
    Color? surfaceVariant,
    Color? border,
    Color? divider,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? error,
    Color? errorLight,
    Color? info,
    Color? infoLight,
    Color? primaryLight,
    Color? accentLight,
    Color? tasks,
    Color? tasksLight,
    LinearGradient? brandGradient,
    LinearGradient? splashGradient,
    List<BoxShadow>? cardShadow,
  }) {
    return WmsThemeExtension(
      cardBackground: cardBackground ?? this.cardBackground,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      primaryLight: primaryLight ?? this.primaryLight,
      accentLight: accentLight ?? this.accentLight,
      tasks: tasks ?? this.tasks,
      tasksLight: tasksLight ?? this.tasksLight,
      brandGradient: brandGradient ?? this.brandGradient,
      splashGradient: splashGradient ?? this.splashGradient,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  WmsThemeExtension lerp(WmsThemeExtension? other, double t) {
    if (other is! WmsThemeExtension) return this;
    return WmsThemeExtension(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      tasks: Color.lerp(tasks, other.tasks, t)!,
      tasksLight: Color.lerp(tasksLight, other.tasksLight, t)!,
      brandGradient: brandGradient,
      splashGradient: splashGradient,
      cardShadow: cardShadow,
    );
  }
}

extension WmsThemeContext on BuildContext {
  WmsThemeExtension get wms =>
      Theme.of(this).extension<WmsThemeExtension>() ?? WmsThemeExtension.light;
}
