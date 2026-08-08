import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_ops_premium_theme.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_ops_premium_widgets.dart';

/// Shared geometry for the stock operations workflow.
abstract final class StockOpsUi {
  /// Vertical gap between fields inside one section.
  static const double fieldGap = AppSpacing.md;

  /// Vertical gap between section cards.
  static const double sectionGap = AppSpacing.md;

  /// Height of the pinned submit bar's button.
  static const double submitButtonHeight = 50;

  /// Icon badge size in a section header.
  static const double sectionIconSize = 32;
}

// ═══════════════════════════════════════════════════════════════════════════
// Section card
// ═══════════════════════════════════════════════════════════════════════════

/// A titled card grouping related form fields.
///
/// Replaces the flat vertical run of nine unlabelled inputs — there was no
/// visual boundary between choosing a warehouse and recording a supplier
/// reference, so the form read as one undifferentiated column.
///
/// Set [collapsible] for genuinely optional groups. Required fields must stay
/// in an always-visible section: the backend rejects movements whose reason is
/// under 10 characters, so hiding the notes field would produce a submit-time
/// error with no field on screen to fix it.
class StockOpsFormSection extends StatefulWidget {
  const StockOpsFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.accent,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.filledCount,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? accent;
  final List<Widget> children;
  final bool collapsible;
  final bool initiallyExpanded;

  /// Optional "n set" hint shown while a collapsible section is closed, so the
  /// user can tell at a glance whether it holds data.
  final int? filledCount;

  @override
  State<StockOpsFormSection> createState() => _StockOpsFormSectionState();
}

class _StockOpsFormSectionState extends State<StockOpsFormSection> {
  late bool _expanded = widget.initiallyExpanded || !widget.collapsible;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;
    final accent = widget.accent ?? palette.brand;
    final filled = widget.filledCount ?? 0;

    final header = Row(
      children: [
        StockOpsIconWell(
          icon: widget.icon,
          color: accent,
          size: StockOpsUi.sectionIconSize,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.cardTitle(context).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  widget.subtitle!,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.collapsible) ...[
          if (!_expanded && filled > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
              ),
              child: Text(
                '$filled set',
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  height: 1.2,
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
          AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: palette.surfaceGradient,
        borderRadius: BorderRadius.circular(StockOpsPalette.radiusCard),
        border: palette.glassBorder(tint: widget.accent),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.collapsible)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: header,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: header,
            ),
          AnimatedCrossFade(
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.children.length; i++) ...[
                    if (i > 0) const SizedBox(height: StockOpsUi.fieldGap),
                    widget.children[i],
                  ],
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Fields
// ═══════════════════════════════════════════════════════════════════════════

/// Text input with a floating label, hairline border and a required marker.
class StockOpsTextField extends StatelessWidget {
  const StockOpsTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.required = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;
  final IconData? prefixIcon;
  final bool required;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      cursorColor: palette.brand,
      style: WmsDesignTokens.body(context).copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: StockOpsFieldChrome.decoration(
        context,
        label: label,
        required: required,
        hint: hint,
        helper: helper,
        errorText: errorText,
        prefixIcon: prefixIcon,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}

/// Shared input chrome so text fields and dropdowns are pixel-identical.
///
/// Both controls are recessed wells rather than outlined boxes: on a form this
/// dense, an outline per field reads as a grid of cages, while a soft fill lets
/// the section card carry the structure.
abstract final class StockOpsFieldChrome {
  static InputDecoration decoration(
    BuildContext context, {
    required String label,
    required bool required,
    String? hint,
    String? helper,
    String? errorText,
    IconData? prefixIcon,
    bool alignLabelWithHint = false,
  }) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;
    final radius = BorderRadius.circular(StockOpsPalette.radiusControl);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,
      helperText: helper,
      errorText: errorText,
      helperMaxLines: 2,
      errorMaxLines: 2,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: palette.insetFill,
      prefixIcon: prefixIcon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(prefixIcon, size: 18, color: palette.brand),
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      labelStyle: WmsDesignTokens.supportingDense(context).copyWith(
        color: colors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: WmsDesignTokens.supportingDense(context).copyWith(
        color: palette.brand,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: WmsDesignTokens.body(context).copyWith(
        color: colors.textTertiary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      helperStyle: WmsDesignTokens.supportingDense(context).copyWith(
        color: colors.textTertiary,
        fontSize: 11.5,
        height: 1.35,
      ),
      errorStyle: WmsDesignTokens.supportingDense(context).copyWith(
        color: colors.error,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      // Roomier than the global default so multi-line notes breathe.
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: border(palette.hairline),
      enabledBorder: border(palette.hairline),
      focusedBorder: border(palette.brand, 1.6),
      errorBorder: border(colors.error),
      focusedErrorBorder: border(colors.error, 1.6),
    );
  }
}

/// Dropdown matching [StockOpsTextField]'s chrome.
class StockOpsDropdownField<T> extends StatelessWidget {
  const StockOpsDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.getLabel,
    required this.onChanged,
    this.value,
    this.hint,
    this.prefixIcon,
    this.required = false,
  });

  final String label;
  final List<T> items;
  final String Function(T item) getLabel;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? hint;
  final IconData? prefixIcon;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;

    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      borderRadius: BorderRadius.circular(StockOpsPalette.radiusControl),
      dropdownColor: colors.surface,
      icon: Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Icon(
          Icons.expand_more_rounded,
          size: 20,
          color: palette.brand,
        ),
      ),
      style: WmsDesignTokens.body(context).copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: StockOpsFieldChrome.decoration(
        context,
        label: label,
        required: required,
        hint: hint,
        prefixIcon: prefixIcon,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            // isExpanded + single line keeps long product names from
            // overflowing the closed field.
            child: Text(
              getLabel(item),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Live summary
// ═══════════════════════════════════════════════════════════════════════════

/// One metric shown in [StockOpsSummaryCard].
class StockOpsSummaryMetric {
  const StockOpsSummaryMetric({
    required this.label,
    required this.value,
    this.icon,
    this.emphasis = false,
    this.tone,
  });

  final String label;
  final String value;
  final IconData? icon;

  /// Renders the value larger — used for the headline figure.
  final bool emphasis;
  final Color? tone;
}

/// Elevated, accent-tinted summary panel that reacts to the form as it is
/// filled in, so the operator can sanity-check before submitting.
class StockOpsSummaryCard extends StatelessWidget {
  const StockOpsSummaryCard({
    super.key,
    required this.metrics,
    this.warning,
    this.accent,
  });

  final List<StockOpsSummaryMetric> metrics;

  /// Blocking message shown inside the card, e.g. quantity over available.
  final String? warning;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final tint = accent ?? colors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: colors.isDark ? 0.16 : 0.08),
            tint.withValues(alpha: colors.isDark ? 0.07 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: colors.isDark ? 0.20 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, size: 16, color: tint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SUMMARY',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.6,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: _SummaryMetricCell(metric: metrics[i])),
              ],
            ],
          ),
          if (warning != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: colors.error.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 15, color: colors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      warning!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetricCell extends StatelessWidget {
  const _SummaryMetricCell({required this.metric});

  final StockOpsSummaryMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          metric.label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: WmsDesignTokens.supportingDense(context).copyWith(
            fontSize: 11,
            color: colors.textSecondary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              maxLines: 1,
              softWrap: false,
              style: WmsDesignTokens.body(context).copyWith(
                fontSize: metric.emphasis ? 19 : 13.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
                letterSpacing: metric.emphasis ? -0.3 : 0,
                color: metric.tone ?? colors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pinned submit bar
// ═══════════════════════════════════════════════════════════════════════════

/// Action bar pinned to the bottom of a form tab.
///
/// The submit control used to be the last item in the scrolling list, so on a
/// long form it sat below the fold and the operator had to scroll to find it.
class StockOpsSubmitBar extends StatelessWidget {
  const StockOpsSubmitBar({
    super.key,
    required this.label,
    required this.icon,
    required this.onSubmit,
    this.submitting = false,
    this.enabled = true,
    this.hint,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSubmit;
  final bool submitting;
  final bool enabled;

  /// Short status line above the button, e.g. missing required fields.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;
    final active = enabled && !submitting;
    // White reads on the gradient; a disabled button loses the gradient, so its
    // label steps down to muted ink rather than staying invisible white.
    // Submitting keeps the gradient — the work is in flight, not blocked.
    final foreground =
        enabled ? const Color(0xFFFFFFFF) : colors.textTertiary;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        // Clears the system gesture inset *and* any bottom navigation bar the
        // host scaffold draws, so the button is never half-hidden.
        AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.8)),
        ),
        boxShadow: [
          BoxShadow(
            color: (colors.isDark ? Colors.black : const Color(0xFF0F172A))
                .withValues(alpha: colors.isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: colors.textSecondary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      hint!,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: colors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // The gradient lives on a decoration behind a transparent
          // FilledButton, so the control keeps Material's focus, ripple and
          // disabled semantics while wearing the premium fill.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(StockOpsPalette.radiusControl),
              gradient: enabled ? palette.brandGradient : null,
              color: enabled ? null : palette.insetFill,
              boxShadow: enabled
                  ? palette.glow(palette.brand, opacity: 0.34, blur: 18, dy: 8)
                  : null,
            ),
            child: SizedBox(
              height: StockOpsUi.submitButtonHeight,
              child: FilledButton(
                onPressed: active ? onSubmit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(StockOpsPalette.radiusControl),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (submitting)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    else
                      Icon(icon, size: 20, color: foreground),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        submitting ? 'Submitting…' : label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: WmsDesignTokens.buttonLabel(context).copyWith(
                          // Explicit: the themed labelLarge carries a dark
                          // on-surface color that would beat foregroundColor.
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab bar
// ═══════════════════════════════════════════════════════════════════════════

/// One operation tab.
class StockOpsTab {
  const StockOpsTab({required this.label, required this.icon, this.badge});

  final String label;
  final IconData icon;

  /// Optional count rendered as a pill on the tab.
  final int? badge;
}

/// Scrollable operation tab strip with icons and count badges.
class StockOpsTabBar extends StatelessWidget implements PreferredSizeWidget {
  const StockOpsTabBar({super.key, required this.tabs});

  final List<StockOpsTab> tabs;

  static const double height = 52;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  /// Colour the selected label wears — also the signal a tab child uses to
  /// detect its own selection, since [TabBar] hands `labelColor` down through
  /// the child's [DefaultTextStyle].
  static const Color selectedLabelColor = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;

    return SizedBox(
      height: height,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        overlayColor: WidgetStatePropertyAll(
          palette.brand.withValues(alpha: 0.06),
        ),
        indicator: BoxDecoration(
          gradient: palette.brandGradient,
          borderRadius: BorderRadius.circular(StockOpsPalette.radiusPill),
          boxShadow: palette.glow(
            palette.brand,
            opacity: 0.34,
            blur: 12,
            dy: 4,
            spread: -3,
          ),
        ),
        labelColor: selectedLabelColor,
        unselectedLabelColor: colors.textSecondary,
        labelPadding: const EdgeInsets.symmetric(horizontal: 3),
        padding: EdgeInsets.zero,
        splashBorderRadius: BorderRadius.circular(StockOpsPalette.radiusPill),
        tabs: [
          for (final tab in tabs)
            Tab(
              height: 38,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      maxLines: 1,
                      softWrap: false,
                      style: WmsDesignTokens.body(context).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (tab.badge != null && tab.badge! > 0) ...[
                      const SizedBox(width: 6),
                      _TabBadge(count: tab.badge!),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabBadge extends StatelessWidget {
  const _TabBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final colors = palette.colors;

    // TabBar propagates labelColor / unselectedLabelColor through the child's
    // DefaultTextStyle, so the badge can match its own tab's state without the
    // tab bar having to rebuild children on every index change.
    final selected = DefaultTextStyle.of(context).style.color ==
        StockOpsTabBar.selectedLabelColor;

    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.24)
            : palette.insetFill,
        borderRadius: BorderRadius.circular(StockOpsPalette.radiusPill),
        border: Border.all(
          color: selected
              ? Colors.white.withValues(alpha: 0.30)
              : colors.border,
        ),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        maxLines: 1,
        softWrap: false,
        style: WmsDesignTokens.supportingDense(context).copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: selected
              ? StockOpsTabBar.selectedLabelColor
              : colors.textSecondary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
