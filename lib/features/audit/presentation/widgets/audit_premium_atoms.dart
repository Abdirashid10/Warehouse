import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_premium_theme.dart';

/// Reusable premium building blocks for the audit activity stream.
///
/// Every atom is theme-aware, overflow-safe at 320dp and free of feature logic.

// ─────────────────────────────────────────────────────────────────────────────
// Surfaces
// ─────────────────────────────────────────────────────────────────────────────

/// Frosted-glass surface with an optional colour-coded leading accent strip.
class AuditGlassCard extends StatelessWidget {
  const AuditGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md + 2),
    this.radius = AuditPalette.radiusCard,
    this.accentStrip,
    this.onTap,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Colour of the leading strip. Null draws no strip.
  final Color? accentStrip;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: elevated ? palette.cardShadow : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: palette.surfaceGradient,
          borderRadius: borderRadius,
          border: palette.glassBorder(tint: accentStrip),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: (accentStrip ?? palette.brand).withValues(alpha: 0.08),
            // The strip is a positioned child so the card keeps sizing to its
            // content. A stretched flex child would demand a bounded height,
            // which a card inside a scroll view never has.
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: accentStrip == null
                        ? 0
                        : AuditPalette.accentStripWidth,
                  ),
                  child: Padding(padding: padding, child: child),
                ),
                if (accentStrip != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: AuditPalette.accentStripWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentStrip!,
                            accentStrip!.withValues(alpha: 0.45),
                          ],
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

/// Duotone icon inside a glowing, gradient-tinted well.
class AuditIconWell extends StatelessWidget {
  const AuditIconWell({
    super.key,
    required this.icon,
    required this.color,
    this.size = 38,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final radius = BorderRadius.circular(size * 0.32);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow:
            palette.glow(color, opacity: 0.26, blur: 14, dy: 5, spread: -4),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: palette.isDark ? 0.30 : 0.20),
              color.withValues(alpha: palette.isDark ? 0.12 : 0.08),
            ],
          ),
          borderRadius: radius,
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Icon(icon, size: size * 0.48, color: color),
        ),
      ),
    );
  }
}

/// Compact tonal badge — the stream's label vocabulary.
class AuditTonePill extends StatelessWidget {
  const AuditTonePill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.tint(color, 0.14),
        borderRadius: BorderRadius.circular(AuditPalette.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                height: 1.15,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

/// Security header — a shielded badge, the stream title and a live activity
/// indicator carrying the number of entries currently loaded.
class AuditSecurityHeader extends StatelessWidget {
  const AuditSecurityHeader({
    super.key,
    required this.totalEntries,
    required this.visibleEntries,
    this.title = 'Activity Stream',
    this.subtitle = 'Immutable record of every action across the platform',
  });

  final int totalEntries;
  final int visibleEntries;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final colors = palette.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: palette.glow(palette.brand, opacity: 0.38, blur: 18),
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: palette.brandGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.sectionTitle(context).copyWith(
                  color: colors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.supporting(context).copyWith(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AuditLiveIndicator(count: visibleEntries),
                  AuditTonePill(
                    label: '$totalEntries total',
                    color: palette.slate,
                    icon: Icons.storage_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Static glow dot marking a live, streaming source.
///
/// Deliberately not animated: a repeating pulse would keep a frame scheduled
/// forever, which stalls `pumpAndSettle` in every test that renders the screen
/// and burns battery on a list users leave open.
class AuditLiveIndicator extends StatelessWidget {
  const AuditLiveIndicator({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final accent = palette.emerald;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.tint(accent, 0.13),
        borderRadius: BorderRadius.circular(AuditPalette.radiusPill),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.55),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '$count shown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: palette.mono(
                color: accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search
// ─────────────────────────────────────────────────────────────────────────────

/// Floating search field — recessed well, vector prefix, one-tap clear.
class AuditSearchBar extends StatelessWidget {
  const AuditSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search user, action, module…',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final colors = palette.colors;

    return Container(
      decoration: BoxDecoration(
        color: palette.insetFill,
        borderRadius: BorderRadius.circular(AuditPalette.radiusControl),
        border: palette.glassBorder(),
        boxShadow: palette.innerWellShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: palette.tint(palette.brand, 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.search_rounded, size: 17, color: palette.brand),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: palette.brand,
              style: WmsDesignTokens.body(context).copyWith(
                color: colors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: WmsDesignTokens.body(context).copyWith(
                  color: colors.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox(width: 4);
              return IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                tooltip: 'Clear search',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 32, height: 32),
                icon: Icon(
                  Icons.cancel_rounded,
                  size: 17,
                  color: colors.textTertiary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filters
// ─────────────────────────────────────────────────────────────────────────────

/// One option in [AuditSegmentedControl].
class AuditSegment<T> {
  const AuditSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// Tactile segmented control with an indicator that glides between segments.
class AuditSegmentedControl<T> extends StatelessWidget {
  const AuditSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<AuditSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final colors = palette.colors;
    final index = segments.indexWhere((s) => s.value == selected);
    final activeIndex = index < 0 ? 0 : index;

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.insetFill,
        borderRadius: BorderRadius.circular(AuditPalette.radiusPill),
        border: palette.glassBorder(),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / segments.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: segmentWidth * activeIndex,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: palette.brandGradient,
                    borderRadius:
                        BorderRadius.circular(AuditPalette.radiusPill),
                    boxShadow: palette.glow(
                      palette.brand,
                      opacity: 0.34,
                      blur: 12,
                      dy: 4,
                      spread: -3,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < segments.length; i++)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onChanged(segments[i].value),
                          borderRadius:
                              BorderRadius.circular(AuditPalette.radiusPill),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              style: WmsDesignTokens.supportingDense(context)
                                  .copyWith(
                                color: i == activeIndex
                                    ? Colors.white
                                    : colors.textSecondary,
                                fontWeight: i == activeIndex
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 12.5,
                                height: 1.15,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  segments[i].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A category option with its own badge count.
class AuditCategory {
  const AuditCategory({
    required this.label,
    required this.count,
    this.value,
  });

  final String label;

  /// Null represents the "All" bucket.
  final String? value;
  final int count;
}

/// Horizontal category pills with badge counters and a crisp active state.
class AuditCategoryChips extends StatelessWidget {
  const AuditCategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<AuditCategory> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final category = categories[i];
          return _CategoryChip(
            category: category,
            selected: category.value == selected,
            onTap: () => onSelected(category.value),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final AuditCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final colors = palette.colors;
    final radius = BorderRadius.circular(AuditPalette.radiusPill);
    final foreground = selected ? Colors.white : colors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: selected
            ? palette.glow(palette.brand,
                opacity: 0.30, blur: 12, dy: 4, spread: -3)
            : null,
      ),
      child: Material(
        color: selected ? Colors.transparent : palette.insetFill,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: selected ? palette.brandGradient : null,
            borderRadius: radius,
            border: selected ? null : palette.glassBorder(),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.22)
                          : palette.tint(palette.brand, 0.13),
                      borderRadius:
                          BorderRadius.circular(AuditPalette.radiusPill),
                    ),
                    child: Text(
                      '${category.count}',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: palette.mono(
                        color: selected ? Colors.white : palette.brand,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline
// ─────────────────────────────────────────────────────────────────────────────

/// Day separator in the stream, e.g. `Today · 12 entries`.
class AuditDayDivider extends StatelessWidget {
  const AuditDayDivider({
    super.key,
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final colors = palette.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: AuditPalette.railWidth,
            child: Center(
              child: Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: colors.textTertiary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WmsDesignTokens.supportingDense(context).copyWith(
                color: colors.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$count',
            style: palette.mono(
              color: colors.textTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Divider(height: 1, thickness: 1, color: palette.hairline),
          ),
        ],
      ),
    );
  }
}

/// One entry in the timeline: a gutter node wired to the entries above and
/// below, plus the log card itself.
class AuditTimelineTile extends StatelessWidget {
  const AuditTimelineTile({
    super.key,
    required this.accent,
    required this.card,
    this.isFirst = false,
    this.isLast = false,
  });

  final Color accent;
  final Widget card;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);

    // Stack sizes to the Row (the card), so the connector can fill the exact
    // card height without an IntrinsicHeight pass on every list item.
    return Stack(
      children: [
        Positioned(
          left: AuditPalette.railWidth / 2 - 0.5,
          top: isFirst ? 22 : 0,
          bottom: isLast ? null : 0,
          height: isLast ? 22 : null,
          width: 1,
          child: ColoredBox(color: palette.hairline),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AuditPalette.railWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 17),
                child: Center(
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: palette.colors.background,
                        width: 2.5,
                      ),
                      boxShadow: palette.glow(
                        accent,
                        opacity: 0.55,
                        blur: 8,
                        dy: 0,
                        spread: -1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: card),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

/// Enterprise empty state with a duotone history mark and a reset affordance.
class AuditEmptyState extends StatelessWidget {
  const AuditEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.onReset,
    this.resetLabel = 'Reset filters',
  });

  final String title;
  final String message;
  final VoidCallback? onReset;
  final String resetLabel;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final colors = palette.colors;

    return AuditGlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Duotone: a soft halo disc behind a crisp glyph.
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          palette.brand.withValues(alpha: 0.22),
                          palette.brand.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.tint(palette.brand, 0.12),
                      border: Border.all(
                        color: palette.brand.withValues(alpha: 0.24),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.manage_search_rounded,
                      size: 26,
                      color: palette.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: WmsDesignTokens.sectionTitle(context).copyWith(
              color: colors.textPrimary,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: WmsDesignTokens.supporting(context).copyWith(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (onReset != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: AuditGradientButton(
                icon: Icons.restart_alt_rounded,
                label: resetLabel,
                onPressed: onReset!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact gradient action button with a soft glow.
class AuditGradientButton extends StatelessWidget {
  const AuditGradientButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.expanded = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final radius = BorderRadius.circular(AuditPalette.radiusPill);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow:
            palette.glow(palette.brand, opacity: 0.36, blur: 18, dy: 8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: palette.brandGradient,
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            splashColor: Colors.white.withValues(alpha: 0.16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.buttonLabel(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
