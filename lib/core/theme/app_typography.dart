import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global text colors — enterprise contrast (Stripe / SAP / Dynamics parity).
abstract final class AppTypographyColors {
  static const Color primaryText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF1F2937);
  static const Color mutedText = Color(0xFF374151);

  /// Operational alert palette — strong, readable on mobile.
  static const Color alertRed = Color(0xFFDC2626);
  static const Color alertOrange = Color(0xFFEA580C);
  static const Color alertGreen = Color(0xFF16A34A);
  static const Color alertBlue = Color(0xFF2563EB);
  static const Color alertPurple = Color(0xFF7C3AED);
}

/// Global font families for Logistics WMS.
abstract final class AppTypography {
  static const String headingFontFamily = 'Poppins';
  static const String bodyFontFamily = 'Inter';

  /// Minimum readable size — never go below this in UI text.
  static const double minFontSize = 12.0;

  // Scale constants (for layout math / EnterpriseDesignSystem).
  static const double pageTitleSize = 26.0;
  static const double pageSubtitleSize = 14.0;
  static const double sectionTitleSize = 20.0;
  static const double cardTitleSize = 15.0;
  static const double cardNumberSize = 24.0;
  static const double bodySize = 14.0;
  static const double descriptionSize = 13.0;
  static const double captionSize = 12.0;
  static const double buttonTextSize = 14.0;
  static const double navLabelSize = 11.0;
  static const double drawerMenuSize = 14.0;
  static const double drawerSectionTitleSize = 15.0;
  static const double drawerAppNameSize = 16.0;
  static const double drawerHeaderSubtitleSize = 13.0;
  static const double legendSize = 13.0;

  @Deprecated('Use AppTextStyles.pageTitle')
  static TextStyle get pageTitle => AppTextStyles.pageTitle;

  @Deprecated('Use AppTextStyles.sectionTitle')
  static TextStyle get sectionTitle => AppTextStyles.sectionTitle;

  @Deprecated('Use AppTextStyles.cardNumber')
  static TextStyle get kpiNumber => AppTextStyles.cardNumber;

  @Deprecated('Use AppTextStyles.cardNumber')
  static TextStyle get kpiNumberCompact => AppTextStyles.cardNumber;

  @Deprecated('Use AppTextStyles.badge')
  static TextStyle get kpiLabel => AppTextStyles.badge;

  @Deprecated('Use AppTextStyles.cardTitle')
  static TextStyle get cardTitle => AppTextStyles.cardTitle;

  @Deprecated('Use AppTextStyles.body')
  static TextStyle get body => AppTextStyles.body;

  @Deprecated('Use AppTextStyles.body')
  static TextStyle get bodyLarge => AppTextStyles.body;

  @Deprecated('Use AppTextStyles.caption')
  static TextStyle get supporting => AppTextStyles.caption;

  @Deprecated('Use AppTextStyles.caption')
  static TextStyle get supportingDense => AppTextStyles.caption;

  @Deprecated('Use AppTextStyles.button')
  static TextStyle get button => AppTextStyles.button;

  @Deprecated('Use AppTextStyles.navigationLabel')
  static TextStyle get bottomNavLabel => AppTextStyles.navigationLabel;

  @Deprecated('Use AppTextStyles.textTheme')
  static TextTheme get textTheme => AppTextStyles.textTheme;

  @Deprecated('Use AppTypography.bodyFontFamily')
  static const String fontFamily = bodyFontFamily;
}

/// Single source of truth for all WMS typography (color-agnostic).
abstract final class AppTextStyles {
  // --- Headings (Poppins) ---

  static TextStyle get pageTitle => GoogleFonts.poppins(
        fontSize: AppTypography.pageTitleSize,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
      );

  static TextStyle get sectionTitle => GoogleFonts.poppins(
        fontSize: AppTypography.sectionTitleSize,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
      );

  static TextStyle get cardTitle => GoogleFonts.poppins(
        fontSize: AppTypography.cardTitleSize,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get cardNumber => GoogleFonts.poppins(
        fontSize: AppTypography.cardNumberSize,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.3,
      );

  static TextStyle get userName => GoogleFonts.poppins(
        fontSize: AppTypography.cardTitleSize,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get button => GoogleFonts.poppins(
        fontSize: AppTypography.buttonTextSize,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.1,
      );

  static TextStyle get drawerMenuItem => GoogleFonts.poppins(
        fontSize: AppTypography.drawerMenuSize,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get drawerMenuItemActive => GoogleFonts.poppins(
        fontSize: AppTypography.drawerMenuSize,
        fontWeight: FontWeight.w700,
        height: 1.35,
      );

  static TextStyle get drawerAppName => GoogleFonts.poppins(
        fontSize: AppTypography.drawerAppNameSize,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  static TextStyle get drawerHeaderSubtitle => GoogleFonts.inter(
        fontSize: AppTypography.drawerHeaderSubtitleSize,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get drawerSectionTitle => GoogleFonts.poppins(
        fontSize: AppTypography.drawerSectionTitleSize,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: 0.4,
      );

  static TextStyle get legend => GoogleFonts.inter(
        fontSize: AppTypography.legendSize,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  // --- Body (Inter) ---

  static TextStyle get pageSubtitle => GoogleFonts.inter(
        fontSize: AppTypography.pageSubtitleSize,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: AppTypography.bodySize,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get description => GoogleFonts.inter(
        fontSize: AppTypography.descriptionSize,
        fontWeight: FontWeight.w500,
        height: 1.45,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w500,
        height: 1.45,
      );

  static TextStyle get email => GoogleFonts.inter(
        fontSize: AppTypography.bodySize,
        fontWeight: FontWeight.w500,
        height: 1.45,
      );

  static TextStyle get formLabel => GoogleFonts.inter(
        fontSize: AppTypography.bodySize,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: AppTypography.bodySize,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  static TextStyle get badge => GoogleFonts.inter(
        fontSize: AppTypography.captionSize,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  static TextStyle get navigationLabel => GoogleFonts.inter(
        fontSize: AppTypography.navLabelSize,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.1,
      );

  static TextStyle get metadata => caption;

  /// Material text theme — headings Poppins, body Inter.
  static TextTheme get textTheme => TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.15,
        ),
        displayMedium: cardNumber,
        displaySmall: pageTitle,
        headlineLarge: sectionTitle,
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        headlineSmall: sectionTitle,
        titleLarge: cardTitle,
        titleMedium: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: AppTypography.descriptionSize,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: description,
        labelLarge: button,
        labelMedium: formLabel,
        labelSmall: caption,
      );
}
