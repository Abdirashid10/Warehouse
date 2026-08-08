import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

/// Visual treatment for a dashboard section header.
enum WmsSectionStyle {
  /// Accent rail + 15px bold title. The established mobile treatment used
  /// across the inventory, orders, products, tasks and profile screens.
  accentRail,

  /// Web-parity `.dash-section` treatment — the whole section is a bordered
  /// surface introduced by a small uppercase, wide-tracked eyebrow label.
  /// Mirrors the web dashboard's section chrome one-for-one.
  webParity,
}

/// Streamlined enterprise section header with an optional count chip and a
/// compact trailing action.
///
/// Set [wrapInCard] to `false` when [child] already provides its own card
/// surface (e.g. metric grids) to avoid nested double-card clutter. It is
/// ignored by [WmsSectionStyle.webParity], where the section *is* the surface.
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
    this.style = WmsSectionStyle.accentRail,
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
  final WmsSectionStyle style;
  final Widget child;

  /// Height of the accent rail — matches the title's cap height.
  static const double _railHeight = 18;
  static const double _railWidth = 3.5;
  static const double _titleInset = _railWidth + AppSpacing.sm;

  /// Web `.dash-section__title` — 11px, semibold, `tracking-wider`, muted.
  static const double _eyebrowFontSize = 11;
  static const double _eyebrowTracking = 0.6;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      WmsSectionStyle.accentRail => _buildAccentRail(context),
      WmsSectionStyle.webParity => _buildWebParity(context),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Web-parity treatment
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildWebParity(BuildContext context) {
    final wms = context.wms;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // p-4
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: wms.cardBackground,
        // rounded-2xl
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        // border-border/60
        border: Border.all(color: wms.border.withValues(alpha: 0.6)),
        // shadow-sm
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A))
                .withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: isDark ? 16 : 2,
            offset: Offset(0, isDark ? 2 : 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    fontSize: _eyebrowFontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: _eyebrowTracking,
                    height: 1.3,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _CountChip(count: count!),
              ],
              if (actionLabel != null && onAction != null)
                _SectionAction(label: actionLabel!, onTap: onAction!),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.description(context),
            ),
          ],
          // mb-3
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Accent-rail treatment (default, unchanged for the rest of the app)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAccentRail(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: _railWidth,
              height: _railHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [primary, primary.withValues(alpha: 0.55)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
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
              _CountChip(count: count!),
            ],
            if (actionLabel != null && onAction != null)
              _SectionAction(label: actionLabel!, onTap: onAction!),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: _titleInset),
            child: Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: wms.primaryLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$count',
        maxLines: 1,
        style: WmsDesignTokens.supportingDense(context).copyWith(
          color: primary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          height: 1.1,
        ),
      ),
    );
  }
}

class _SectionAction extends StatelessWidget {
  const _SectionAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.xs,
        ),
        minimumSize: const Size(0, AppSpacing.minTouchTarget),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: primary,
        visualDensity: VisualDensity.compact,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.2,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18),
        ],
      ),
    );
  }
}
