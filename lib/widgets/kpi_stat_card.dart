import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

class KPIStatCard extends StatelessWidget {
  const KPIStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.onTap,
    this.premium = false,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onTap;
  final bool premium;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = WmsUiColors.of(context);
        final accent = accentColor ?? iconColor ?? colors.primary;
        final iconFg = iconColor ?? accent;
        final iconBg = iconBackgroundColor ?? colors.primaryMuted;

        final maxH = constraints.maxHeight;
        final compact = maxH.isFinite && maxH < 168;
        final iconPadding =
            compact ? AppSpacing.sm : WmsIconSizes.iconCardPadding;
        final iconSize = compact ? WmsIconSizes.listLeading : WmsIconSizes.kpi;

        return AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(AppSpacing.md),
          accentColor: premium ? accent : null,
          elevated: premium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: premium
                      ? Border.all(color: iconFg.withValues(alpha: 0.18))
                      : null,
                ),
                child: Icon(icon, size: iconSize, color: iconFg),
              ),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.kpiValue(
                    context,
                    width: constraints.maxWidth,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.kpiLabel(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
