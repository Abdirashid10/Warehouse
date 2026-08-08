import 'package:flutter/material.dart';

/// Canonical WMS theme palette — single source of truth for light and dark modes.
abstract final class AppThemeColors {
  // Light theme
  static const lightBackground = Color(0xFFF5F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF1F5F9);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightPrimary = Color(0xFF2563EB);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF1F2937);
  static const lightTextTertiary = Color(0xFF374151);

  // Dark theme
  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111827);
  static const darkCard = Color(0xFF172033);
  static const darkSurfaceVariant = Color(0xFF1F2937);
  static const darkBorder = Color(0xFF243047);
  static const darkPrimary = Color(0xFF3B82F6);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFCBD5E1);
  static const darkTextTertiary = Color(0xFF64748B);

  // Semantic — shared across themes
  static const success = Color(0xFF16A34A);
  static const successDark = Color(0xFF22C55E);
  static const warning = Color(0xFFEA580C);
  static const danger = Color(0xFFDC2626);

  /// Text on gradient / primary-colored surfaces (always high contrast).
  static const onGradient = Color(0xFFFFFFFF);
  static const onPrimaryButton = Color(0xFFFFFFFF);
}
