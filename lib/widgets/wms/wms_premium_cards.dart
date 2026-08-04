import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';

/// Shared premium icon badge — soft tinted rounded square with a matching
/// border and centered glyph (web-dashboard parity).
class WmsPremiumIconBadge extends StatelessWidget {
  const WmsPremiumIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize,
    this.showRing = true,
  });

  final IconData icon;
  final Color color;

  /// Outer size of the badge container.
  final double size;

  /// Optional explicit icon glyph size. Defaults to [size] * 0.5.
  final double? iconSize;

  /// Whether to draw the subtle matching-colored border around the badge.
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final glyphSize = iconSize ?? size * 0.5;
    final radius = BorderRadius.circular(size * 0.28);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: radius,
        border: showRing
            ? Border.all(color: color.withValues(alpha: 0.14), width: 1)
            : null,
      ),
      child: Icon(
        icon,
        size: glyphSize,
        color: color,
      ),
    );
  }
}

/// Holds the fixed visual layout for a premium metric card used by both
/// the command-center sections and the warehouse control-center body.
abstract final class WmsPremiumMetricCard {
  /// Size of the rounded icon badge shown on metric cards.
  static const double badgeSize = 42;

  /// Larger, striking metric number size.
  static const double metricFontSize = 24;

  /// Compact metric number size (used inside tight 2-col phone grids).
  static const double metricFontSizeCompact = 22;

  /// Internal card padding for premium metric cards.
  static const EdgeInsets cardPadding = EdgeInsets.all(AppSpacing.md);

  /// Vertical gap between icon row and metric value.
  static const double iconToMetricGap = AppSpacing.sm;

  /// Vertical gap between metric value and label.
  static const double metricToLabelGap = 3;

  /// Icon glyph size inside the badge.
  static const double badgeIconSize = WmsIconSizes.kpi;

  /// Shared soft tint helper for building preview/placeholder tints.
  static Color tint(Color color) => color.withValues(alpha: 0.10);
}

