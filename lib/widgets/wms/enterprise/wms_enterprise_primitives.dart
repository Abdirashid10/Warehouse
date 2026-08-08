import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

/// Standard enterprise command-center header shell used across WMS screens.
class WmsExecutiveHeaderShell extends StatelessWidget {
  const WmsExecutiveHeaderShell({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(
        WmsDesignTokens.screenPadding,
        AppSpacing.sm,
        WmsDesignTokens.screenPadding,
        MobileUi.headerBottomGap(width),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || trailing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WmsDesignTokens.supporting(context).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          if (subtitle != null) ...[
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: wms.textTertiary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          child,
        ],
      ),
    );
  }
}

/// Unified KPI tile for executive summaries across all modules.
class WmsKpiTile extends StatelessWidget {
  const WmsKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.compactValue = false,
    this.horizontal = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool compactValue;
  final bool horizontal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final content = horizontal
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: WmsDesignTokens.kpiIconSize, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: WmsDesignTokens.kpiValue(context, width: width),
                    ),
                    Text(label, style: WmsDesignTokens.kpiLabel(context)),
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: WmsDesignTokens.kpiIconSize, color: color),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                maxLines: compactValue ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.kpiValue(context, width: width),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.kpiLabel(context),
              ),
            ],
          );

    return AppCard(
      elevated: true,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: content,
    );
  }
}

/// Responsive 2×2 (phone) or 4-column (tablet) KPI grid.
class WmsKpiGrid extends StatelessWidget {
  const WmsKpiGrid({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = WmsDesignTokens.kpiTileWidth(
          constraints.maxWidth,
          width,
        );
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Standard enterprise filter chip with color accent.
class WmsEnterpriseFilterChip extends StatelessWidget {
  const WmsEnterpriseFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(label, style: WmsDesignTokens.body(context)),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: icon != null
          ? Icon(icon, size: WmsIconSizes.status, color: accent)
          : color != null
              ? Icon(Icons.circle, size: 8, color: accent)
              : null,
      selectedColor: accent.withValues(alpha: 0.12),
      side: BorderSide(color: accent.withValues(alpha: 0.28)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

/// Compact card action button row item.
class WmsCardAction extends StatelessWidget {
  const WmsCardAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final accent = color ?? Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: WmsIconSizes.minTouchTarget,
            minHeight: WmsIconSizes.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: WmsIconSizes.actionButton, color: accent),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: WmsDesignTokens.minReadableFontSize,
                        fontWeight: FontWeight.w600,
                        color: wms.textSecondary,
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
