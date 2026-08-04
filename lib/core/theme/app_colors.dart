import 'package:flutter/material.dart';

/// Enterprise WMS color system — primary blue with semantic status colors.
abstract final class AppColors {
  // Brand — professional enterprise blue
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color accent = Color(0xFF0EA5E9);
  static const Color accentLight = Color(0xFFE0F2FE);

  // Neutrals
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Text — high-contrast enterprise palette
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF1F2937);
  static const Color textTertiary = Color(0xFF374151);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status — strong operational colors
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFEA580C);
  static const Color warningLight = Color(0xFFFFEDD5);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Domain semantics (operations & modules)
  static const Color tasks = Color(0xFF7C3AED);
  static const Color tasksLight = Color(0xFFEDE9FE);
  static const Color outbound = Color(0xFFC2410C);
  static const Color outboundLight = Color(0xFFFFEDD5);
  static const Color expired = Color(0xFF7C3AED);
  static const Color expiredLight = Color(0xFFEDE9FE);
  static const Color processing = Color(0xFF1D4ED8);
  static const Color processingLight = Color(0xFFDBEAFE);

  static const Color indigo = Color(0xFF2563EB);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient primaryGradient = brandGradient;

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
  );

  static const LinearGradient cardAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
  );

  /// NexusLogistics enterprise warehouse control center gradient.
  static const LinearGradient logisticsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7), Color(0xFF0369A1)],
    stops: [0.0, 0.45, 1.0],
  );

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF2563EB).withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}
