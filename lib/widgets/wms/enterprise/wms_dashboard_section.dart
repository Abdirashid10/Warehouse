import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

/// Consistent enterprise section header with accent bar and optional action.
///
/// Set [wrapInCard] to `false` when [child] already provides its own card
/// surface (e.g. KPI grids) to avoid nested double-card clutter.
class WmsDashboardSection extends StatelessWidget {
  const WmsDashboardSection({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.count,
    this.wrapInCard = true,
    this.cardPadding,
    this.showAccentBorder = true,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int? count;
  final bool wrapInCard;
  final EdgeInsetsGeometry? cardPadding;
  final bool showAccentBorder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3.5,
              height: 18,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.sectionTitle(context).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: wms.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: const Size(
                    AppSpacing.minTouchTarget,
                    AppSpacing.minTouchTarget,
                  ),
                  foregroundColor: primary,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              subtitle!,
              style: WmsDesignTokens.description(context),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (wrapInCard)
          AppCard(
            padding: cardPadding ?? const EdgeInsets.all(AppSpacing.lg),
            elevated: true,
            accentColor:
                showAccentBorder ? primary.withValues(alpha: 0.9) : null,
            child: child,
          )
        else
          child,
      ],
    );
  }
}
