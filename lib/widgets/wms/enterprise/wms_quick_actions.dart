import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

class WmsQuickAction {
  const WmsQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.iconBackground,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBackground;
}

class WmsQuickActionsSection extends StatelessWidget {
  const WmsQuickActionsSection({
    super.key,
    required this.actions,
    this.title = 'Quick Actions',
    this.compact = false,
    this.showSubtitle = true,
    this.premium = false,
  });

  final String title;
  final List<WmsQuickAction> actions;
  final bool compact;
  final bool showSubtitle;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = MobileUi.quickActionColumns(width);
    final tileHeight = MobileUi.quickActionTileHeight(width);
    final spacing = compact ? AppSpacing.sm : AppSpacing.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
              ),
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Frequently used warehouse operations',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: wms.textSecondary,
                ),
          ),
        ],
        SizedBox(height: showSubtitle ? AppSpacing.md : AppSpacing.sm),
        GridView.builder(
          itemCount: actions.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: tileHeight,
          ),
          itemBuilder: (context, index) => _QuickActionCard(
            action: actions[index],
            compact: compact,
            premium: premium,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.action,
    required this.compact,
    this.premium = false,
  });

  final WmsQuickAction action;
  final bool compact;
  final bool premium;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final iconBg = widget.action.iconBackground ?? colors.primaryMuted;
    final iconColor = widget.action.iconColor ?? primary;
    final labelSize = widget.compact ? 11.0 : 12.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: AppCard(
          onTap: widget.action.onTap,
          padding: const EdgeInsets.all(AppSpacing.sm),
          elevated: widget.premium,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(WmsIconSizes.iconCardPadding),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  widget.action.icon,
                  color: iconColor,
                  size: WmsIconSizes.dashboardCard,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.action.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: labelSize,
                      height: 1.1,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
