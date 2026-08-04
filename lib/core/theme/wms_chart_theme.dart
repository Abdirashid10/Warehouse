import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

/// Chart styling that adapts to the active application theme.
class WmsChartTheme {
  const WmsChartTheme._({
    required this.colors,
    required this.axisLabelStyle,
    required this.legendLabelStyle,
    required this.legendValueStyle,
    required this.emptyMessageStyle,
    required this.tooltipStyle,
    required this.sectionBackground,
    required this.cardBackground,
    required this.border,
    required this.gridColor,
  });

  factory WmsChartTheme.of(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return WmsChartTheme._(
      colors: colors,
      axisLabelStyle: WmsDesignTokens.chartAxis(context).copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      legendLabelStyle: WmsDesignTokens.legend(context),
      legendValueStyle: WmsDesignTokens.legend(context).copyWith(
        fontWeight: FontWeight.w700,
      ),
      emptyMessageStyle: WmsDesignTokens.supporting(context).copyWith(
        color: colors.textSecondary,
      ),
      tooltipStyle: WmsDesignTokens.supportingDense(context).copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      sectionBackground: colors.background,
      cardBackground: colors.surface,
      border: colors.border,
      gridColor: colors.chartGrid,
    );
  }

  final WmsUiColors colors;
  final TextStyle axisLabelStyle;
  final TextStyle legendLabelStyle;
  final TextStyle legendValueStyle;
  final TextStyle emptyMessageStyle;
  final TextStyle tooltipStyle;
  final Color sectionBackground;
  final Color cardBackground;
  final Color border;
  final Color gridColor;

  static Color categoryColor(int index, {required bool isDark}) {
    if (!isDark) {
      const lightColors = [
        Color(0xFF2563EB),
        Color(0xFF0284C7),
        Color(0xFF0EA5E9),
        Color(0xFF16A34A),
        Color(0xFFEA580C),
        Color(0xFFDC2626),
        Color(0xFF7C3AED),
        Color(0xFF0D9488),
      ];
      return lightColors[index % lightColors.length];
    }

    const darkColors = [
      Color(0xFF60A5FA),
      Color(0xFF38BDF8),
      Color(0xFF4ADE80),
      Color(0xFFFBBF24),
      Color(0xFFFB923C),
      Color(0xFFF87171),
      Color(0xFFA78BFA),
      Color(0xFFCBD5E1),
    ];
    return darkColors[index % darkColors.length];
  }

  static List<({String label, Color color})> stockStatusSegments(
    WmsUiColors colors,
  ) {
    return [
      (label: 'In Stock', color: colors.success),
      (label: 'Low Stock', color: colors.warning),
      (label: 'Out Of Stock', color: colors.error),
      (label: 'Expired', color: colors.expired),
      (label: 'No Inventory', color: colors.textSecondary),
    ];
  }
}
