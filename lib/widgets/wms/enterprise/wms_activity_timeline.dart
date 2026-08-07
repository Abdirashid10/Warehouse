import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Semantic role of a timeline entry.
///
/// Entries carry a tone rather than a literal colour so the pair is resolved
/// against the active theme at paint time. Baking colours in at mapping time
/// meant an entry built under one brightness kept those colours after a theme
/// switch — light-mode tints stayed on dark surfaces.
enum WmsTimelineTone {
  success,
  info,
  accent,
  primary,
  warning,
  error,
  outbound,
  expired,
  neutral,
}

class WmsTimelineEntry {
  const WmsTimelineEntry({
    required this.title,
    required this.description,
    required this.relativeTime,
    required this.icon,
    this.tone = WmsTimelineTone.primary,
    this.iconColor,
    this.iconBackground,
  });

  final String title;
  final String description;
  final String relativeTime;
  final IconData icon;
  final WmsTimelineTone tone;

  /// Explicit override for the glyph colour. Prefer [tone]; this exists for
  /// callers that genuinely need a one-off colour and are already resolving it
  /// from the theme themselves.
  final Color? iconColor;

  /// Explicit override for the well behind the glyph. Prefer [tone].
  final Color? iconBackground;

  Color resolveIconColor(WmsUiColors colors) =>
      iconColor ?? _toneInk(tone, colors);

  Color resolveIconBackground(WmsUiColors colors) =>
      iconBackground ?? _toneFill(tone, colors);

  static Color _toneInk(WmsTimelineTone tone, WmsUiColors colors) =>
      switch (tone) {
        WmsTimelineTone.success => colors.success,
        WmsTimelineTone.info => colors.info,
        WmsTimelineTone.accent => colors.accent,
        WmsTimelineTone.primary => colors.primary,
        WmsTimelineTone.warning => colors.warning,
        WmsTimelineTone.error => colors.error,
        WmsTimelineTone.outbound => colors.outbound,
        WmsTimelineTone.expired => colors.expired,
        WmsTimelineTone.neutral => colors.textSecondary,
      };

  static Color _toneFill(WmsTimelineTone tone, WmsUiColors colors) =>
      switch (tone) {
        WmsTimelineTone.success => colors.successMuted,
        WmsTimelineTone.info => colors.infoMuted,
        WmsTimelineTone.accent => colors.accentMuted,
        WmsTimelineTone.primary => colors.primaryMuted,
        WmsTimelineTone.warning => colors.warningMuted,
        WmsTimelineTone.error => colors.errorMuted,
        WmsTimelineTone.outbound => colors.warningMuted,
        WmsTimelineTone.expired => colors.expiredMuted,
        WmsTimelineTone.neutral => colors.mutedSurface,
      };
}

/// Maps audit/action text to timeline presentation.
abstract final class WmsTimelineMapper {
  static WmsTimelineEntry fromActionText({
    required String action,
    String? userName,
    String? relativeTime,
  }) {
    final lower = action.toLowerCase();
    final IconData icon;
    final WmsTimelineTone tone;
    String title;

    if (lower.contains('order') && lower.contains('deliver')) {
      icon = Icons.local_shipping_outlined;
      tone = WmsTimelineTone.success;
      title = 'Order Delivered';
    } else if (lower.contains('order') && lower.contains('pack')) {
      icon = Icons.inventory_2_outlined;
      tone = WmsTimelineTone.info;
      title = 'Order Packed';
    } else if (lower.contains('order')) {
      icon = Icons.shopping_bag_outlined;
      tone = WmsTimelineTone.accent;
      title = 'Order Created';
    } else if (lower.contains('task') && lower.contains('complet')) {
      icon = Icons.task_alt_rounded;
      tone = WmsTimelineTone.success;
      title = 'Task Completed';
    } else if (lower.contains('transfer')) {
      icon = Icons.swap_horiz_rounded;
      tone = WmsTimelineTone.info;
      title = 'Stock Transferred';
    } else if (lower.contains('user') || lower.contains('added')) {
      icon = Icons.person_add_alt_1_outlined;
      tone = WmsTimelineTone.primary;
      title = 'User Added';
    } else if (lower.contains('inventory') || lower.contains('stock')) {
      icon = Icons.inventory_2_outlined;
      tone = WmsTimelineTone.primary;
      title = 'Inventory Updated';
    } else if (lower.contains('inbound') || lower.contains('receive')) {
      icon = Icons.download_rounded;
      tone = WmsTimelineTone.success;
      title = 'Inbound Received';
    } else if (lower.contains('outbound') || lower.contains('dispatch')) {
      icon = Icons.upload_rounded;
      tone = WmsTimelineTone.outbound;
      title = 'Outbound Dispatched';
    } else if (lower.contains('warehouse')) {
      icon = Icons.warehouse_outlined;
      tone = WmsTimelineTone.info;
      title = 'Warehouse Event';
    } else if (lower.contains('alert') || lower.contains('critical')) {
      icon = Icons.warning_amber_rounded;
      tone = WmsTimelineTone.warning;
      title = 'Operations Alert';
    } else {
      icon = Icons.history_rounded;
      tone = WmsTimelineTone.neutral;
      title = _titleFromAction(action);
    }

    final description = userName != null && userName.isNotEmpty
        ? '$userName · $action'
        : action;

    return WmsTimelineEntry(
      title: title,
      description: description,
      relativeTime: relativeTime ?? '',
      icon: icon,
      tone: tone,
    );
  }

  static String _titleFromAction(String action) {
    final trimmed = action.trim();
    if (trimmed.isEmpty) return 'Warehouse Event';
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= 3) return trimmed;
    return '${words.take(3).join(' ')}…';
  }

  static WmsTimelineEntry fromMovement({
    required String type,
    required String productName,
    required String quantityLabel,
    required String relativeTime,
  }) {
    final upper = type.toUpperCase();
    IconData icon;
    WmsTimelineTone tone;
    String title;

    switch (upper) {
      case 'INBOUND':
        icon = Icons.download_rounded;
        tone = WmsTimelineTone.success;
        title = 'Inbound Received';
        break;
      case 'OUTBOUND':
        icon = Icons.upload_rounded;
        tone = WmsTimelineTone.outbound;
        title = 'Outbound Dispatched';
        break;
      case 'TRANSFER':
        icon = Icons.swap_horiz_rounded;
        tone = WmsTimelineTone.info;
        title = 'Stock Transferred';
        break;
      default:
        icon = Icons.inventory_2_outlined;
        tone = WmsTimelineTone.primary;
        title = 'Inventory Updated';
    }

    return WmsTimelineEntry(
      title: title,
      description: '$productName · $quantityLabel',
      relativeTime: relativeTime,
      icon: icon,
      tone: tone,
    );
  }
}

class WmsActivityTimeline extends StatelessWidget {
  const WmsActivityTimeline({
    super.key,
    required this.entries,
    this.title = 'Recent Activity',
    this.actionLabel,
    this.onAction,
    this.maxItems = 8,
    this.dense = false,
    this.useSectionAccent = false,
    this.concise = false,
    this.embedded = false,
  });

  final String title;
  final List<WmsTimelineEntry> entries;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int maxItems;
  final bool dense;
  final bool useSectionAccent;
  final bool concise;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final visible = entries.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty)
          Row(
            children: [
              if (useSectionAccent) ...[
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(actionLabel!),
                ),
            ],
          ),
        if (title.isNotEmpty)
          SizedBox(height: dense ? AppSpacing.sm : AppSpacing.md),
        if (visible.isEmpty)
          const AppCard(
            child: WmsEmptyState(
              title: 'No recent activity',
              message: 'Operations and updates will appear here.',
              icon: Icons.timeline_outlined,
            ),
          )
        else if (embedded)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0)
                  SizedBox(height: dense ? AppSpacing.sm : AppSpacing.md),
                WmsTimelineEntryTile(
                  entry: visible[i],
                  showConnector: i < visible.length - 1,
                  dense: dense,
                  concise: concise,
                ),
              ],
            ],
          )
        else
          AppCard(
            padding: EdgeInsets.symmetric(
              vertical: dense ? AppSpacing.sm : AppSpacing.md,
              horizontal: AppSpacing.md,
            ),
            elevated: concise,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    SizedBox(height: dense ? AppSpacing.sm : AppSpacing.md),
                  WmsTimelineEntryTile(
                    entry: visible[i],
                    showConnector: i < visible.length - 1,
                    dense: dense,
                    concise: concise,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class WmsTimelineEntryTile extends StatelessWidget {
  const WmsTimelineEntryTile({
    super.key,
    required this.entry,
    required this.showConnector,
    this.dense = false,
    this.concise = false,
  });

  final WmsTimelineEntry entry;
  final bool showConnector;
  final bool dense;
  final bool concise;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final iconSize = dense ? 32.0 : 40.0;
    final iconInk = entry.resolveIconColor(colors);
    final iconWell = entry.resolveIconBackground(colors);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: iconSize,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconWell,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: concise
                      ? Border.all(
                          color: iconInk.withValues(alpha: 0.18),
                        )
                      : null,
                ),
                child: Icon(entry.icon,
                    color: iconInk, size: dense ? 16 : 20),
              ),
              if (showConnector)
                Container(
                  width: 2,
                  height: dense ? 20 : 28,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (entry.relativeTime.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.mutedSurface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          entry.relativeTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WmsDesignTokens.supportingDense(context).copyWith(
                                color: colors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                  ],
                ),
                if (!concise) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
