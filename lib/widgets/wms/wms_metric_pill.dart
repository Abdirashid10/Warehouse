import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

/// One metric in a [WmsMetricPillBar].
class WmsMetricPillData {
  const WmsMetricPillData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// Makes the pill a control rather than a readout.
  final VoidCallback? onTap;

  /// Renders the pill in its active state.
  final bool selected;
}

/// Horizontally scrollable strip of compact metric pills.
///
/// The alternative — a two-column grid of tall KPI cards — costs roughly 500dp
/// for six metrics, which is more than a phone screen before any content is
/// visible. This strip fits the same six in ~78dp and scrolls for the rest.
class WmsMetricPillBar extends StatelessWidget {
  const WmsMetricPillBar({
    super.key,
    required this.metrics,
    this.pillWidth = defaultPillWidth,
    this.padding,
  });

  final List<WmsMetricPillData> metrics;

  /// Width of each pill. Widen for metrics carrying long values (currency).
  final double pillWidth;

  final EdgeInsetsGeometry? padding;

  static const double height = 78;
  static const double defaultPillWidth = 132;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        itemCount: metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) => WmsMetricPill(
          data: metrics[index],
          width: pillWidth,
        ),
      ),
    );
  }
}

/// Compact metric tile — icon + label on one line, value beneath.
class WmsMetricPill extends StatelessWidget {
  const WmsMetricPill({
    super.key,
    required this.data,
    this.width = WmsMetricPillBar.defaultPillWidth,
  });

  final WmsMetricPillData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    final selected = data.selected;

    return SizedBox(
      width: width,
      child: Material(
        color:
            selected ? data.color.withValues(alpha: 0.10) : colors.cardBackground,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: data.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? data.color.withValues(alpha: 0.45)
                    : colors.border.withValues(alpha: 0.7),
                width: selected ? 1.4 : 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(data.icon, size: 14, color: data.color),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        data.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: WmsDesignTokens.supportingDense(context).copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // scaleDown keeps six-figure counts and currency on one line.
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data.value,
                      maxLines: 1,
                      softWrap: false,
                      style: WmsDesignTokens.kpiValue(context).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -0.4,
                        color: selected ? data.color : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
