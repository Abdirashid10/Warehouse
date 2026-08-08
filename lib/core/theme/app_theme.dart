import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_theme_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_typography.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';

abstract final class AppTheme {
  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        extension: WmsThemeExtension.light,
        scaffoldBackground: AppThemeColors.lightBackground,
        surface: AppThemeColors.lightSurface,
        onSurface: AppThemeColors.lightTextPrimary,
        onSurfaceVariant: AppThemeColors.lightTextSecondary,
        primary: AppThemeColors.lightPrimary,
        overlayStyle: SystemUiOverlayStyle.dark,
      );

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        extension: WmsThemeExtension.dark,
        scaffoldBackground: AppThemeColors.darkBackground,
        surface: AppThemeColors.darkSurface,
        onSurface: AppThemeColors.darkTextPrimary,
        onSurfaceVariant: AppThemeColors.darkTextSecondary,
        primary: AppThemeColors.darkPrimary,
        overlayStyle: SystemUiOverlayStyle.light,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required WmsThemeExtension extension,
    required Color scaffoldBackground,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color primary,
    required SystemUiOverlayStyle overlayStyle,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: AppThemeColors.onPrimaryButton,
      secondary: isDark ? const Color(0xFF38BDF8) : AppColors.accent,
      onSecondary: isDark ? AppThemeColors.darkBackground : Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      error: extension.error,
      onError: Colors.white,
      outline: extension.border,
    );

    final textTheme = AppTextStyles.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,
      extensions: [extension],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: surface,
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: onSurface, size: WmsIconSizes.header),
        systemOverlayStyle: overlayStyle,
        titleTextStyle: textTheme.displaySmall?.copyWith(color: onSurface),
      ),
      iconTheme: IconThemeData(color: onSurface, size: WmsIconSizes.listLeading),
      cardTheme: CardThemeData(
        elevation: 0,
        color: extension.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: extension.border.withValues(alpha: 0.8)),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
        backgroundColor: surface,
        indicatorColor: extension.primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          final inactive = isDark
              ? colorScheme.onSurfaceVariant
              : AppThemeColors.lightTextSecondary;
          return AppTextStyles.navigationLabel.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? colorScheme.primary : inactive,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          final inactive = isDark
              ? colorScheme.onSurfaceVariant
              : AppThemeColors.lightTextSecondary;
          return IconThemeData(
            size: WmsIconSizes.bottomNav,
            color: selected ? colorScheme.primary : inactive,
          );
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: extension.cardBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: extension.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: extension.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: extension.error),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? extension.textTertiary : AppThemeColors.lightTextTertiary,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: AppTextStyles.formLabel.copyWith(
          color: isDark ? extension.textSecondary : AppThemeColors.lightTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          textStyle: AppTextStyles.button.copyWith(color: colorScheme.onPrimary),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          side: BorderSide(color: extension.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: AppTextStyles.button,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return extension.cardBackground;
        }),
        side: BorderSide(color: extension.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dividerTheme: DividerThemeData(
        color: extension.divider,
        thickness: 1,
        space: 1,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            WmsIconSizes.minTouchTarget,
            WmsIconSizes.minTouchTarget,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          iconSize: WmsIconSizes.header,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurface,
        minLeadingWidth: WmsIconSizes.listLeading + WmsIconSizes.iconCardPadding,
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: isDark ? onSurfaceVariant : AppThemeColors.lightTextSecondary,
          fontWeight: FontWeight.w500,
        ),
        leadingAndTrailingTextStyle: textTheme.bodyMedium?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? extension.surfaceVariant : onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? onSurface : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(visualDensity: VisualDensity.compact),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return extension.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return extension.border;
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
