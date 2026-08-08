import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_badge_colors.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

class WmsTaskStatusBadge extends StatelessWidget {
  const WmsTaskStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.useFullLabel = false,
  });

  final String status;
  final bool compact;
  final bool useFullLabel;

  static Color foregroundFor(String status, [BuildContext? context]) {
    if (context != null) {
      return WmsBadgeColors.taskStatus(WmsUiColors.of(context), status).fg;
    }
    return WmsBadgeColors.taskStatus(_fallbackColors(false), status).fg;
  }

  static Color backgroundFor(String status, [BuildContext? context]) {
    if (context != null) {
      return WmsBadgeColors.taskStatus(WmsUiColors.of(context), status).bg;
    }
    return WmsBadgeColors.taskStatus(_fallbackColors(false), status).bg;
  }

  static IconData iconFor(String status) {
    switch (status) {
      case WmsTaskStatuses.pending:
        return Icons.schedule_outlined;
      case WmsTaskStatuses.accepted:
        return Icons.thumb_up_alt_outlined;
      case WmsTaskStatuses.inProgress:
        return Icons.play_circle_outline;
      case WmsTaskStatuses.waitingConfirmation:
        return Icons.hourglass_top_outlined;
      case WmsTaskStatuses.completed:
        return Icons.check_circle_outline;
      case WmsTaskStatuses.overdue:
        return Icons.event_busy_outlined;
      case WmsTaskStatuses.rejected:
        return Icons.cancel_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  static String labelFor(String status, {bool full = false}) {
    if (full && status == WmsTaskStatuses.waitingConfirmation) {
      return 'Waiting Confirmation';
    }
    return WmsTaskStatuses.displayLabel(status);
  }

  @override
  Widget build(BuildContext context) {
    final palette = WmsBadgeColors.taskStatus(WmsUiColors.of(context), status);
    return _BadgeChip(
      label: labelFor(status, full: useFullLabel),
      background: palette.bg,
      foreground: palette.fg,
      compact: compact,
      icon: iconFor(status),
    );
  }
}

class WmsTaskPriorityBadge extends StatelessWidget {
  const WmsTaskPriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
    this.showIcon = true,
  });

  final String priority;
  final bool compact;
  final bool showIcon;

  static Color foregroundFor(String priority, [BuildContext? context]) {
    if (context != null) {
      return WmsBadgeColors.taskPriority(WmsUiColors.of(context), priority).fg;
    }
    return WmsBadgeColors.taskPriority(_fallbackColors(false), priority).fg;
  }

  static Color backgroundFor(String priority, [BuildContext? context]) {
    if (context != null) {
      return WmsBadgeColors.taskPriority(WmsUiColors.of(context), priority).bg;
    }
    return WmsBadgeColors.taskPriority(_fallbackColors(false), priority).bg;
  }

  static IconData iconFor(String priority) {
    switch (priority.toLowerCase()) {
      case WmsTaskPriorities.low:
        return Icons.arrow_downward_rounded;
      case WmsTaskPriorities.high:
        return Icons.arrow_upward_rounded;
      case WmsTaskPriorities.critical:
        return Icons.priority_high_rounded;
      default:
        return Icons.drag_handle_rounded;
    }
  }

  static String labelFor(String priority) => priority.isEmpty
      ? priority
      : priority[0].toUpperCase() + priority.substring(1);

  @override
  Widget build(BuildContext context) {
    final palette = WmsBadgeColors.taskPriority(
      WmsUiColors.of(context),
      priority,
    );
    return _BadgeChip(
      label: labelFor(priority),
      background: palette.bg,
      foreground: palette.fg,
      compact: compact,
      icon: showIcon ? iconFor(priority) : null,
    );
  }
}

class WmsOrderStatusBadge extends StatelessWidget {
  const WmsOrderStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  static Color foregroundFor(String status, [BuildContext? context]) {
    if (context != null) {
      return WmsBadgeColors.orderStatus(WmsUiColors.of(context), status).fg;
    }
    return WmsBadgeColors.orderStatus(_fallbackColors(false), status).fg;
  }

  static Color backgroundFor(String status, [BuildContext? context]) {
    if (context != null) {
      return WmsBadgeColors.orderStatus(WmsUiColors.of(context), status).bg;
    }
    return WmsBadgeColors.orderStatus(_fallbackColors(false), status).bg;
  }

  static IconData iconFor(String status) {
    switch (status) {
      case WmsOrderStatuses.pending:
        return Icons.schedule_outlined;
      case WmsOrderStatuses.processing:
        return Icons.inventory_2_outlined;
      case WmsOrderStatuses.packed:
        return Icons.inventory_outlined;
      case WmsOrderStatuses.shipped:
        return Icons.local_shipping_outlined;
      case WmsOrderStatuses.delivered:
        return Icons.task_alt_outlined;
      default:
        if (status.toLowerCase() == 'cancelled') {
          return Icons.cancel_outlined;
        }
        return Icons.shopping_cart_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = WmsBadgeColors.orderStatus(WmsUiColors.of(context), status);
    return _BadgeChip(
      label: status,
      background: palette.bg,
      foreground: palette.fg,
      compact: compact,
      icon: iconFor(status),
    );
  }
}

class WmsStockStatusBadge extends StatelessWidget {
  const WmsStockStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  static Color foregroundFor(String status, [BuildContext? context]) {
    if (context != null) {
      return WmsBadgeColors.stockStatus(WmsUiColors.of(context), status).fg;
    }
    return WmsBadgeColors.stockStatus(_fallbackColors(false), status).fg;
  }

  static Color backgroundFor(String status, [BuildContext? context]) {
    if (context != null) {
      return WmsBadgeColors.stockStatus(WmsUiColors.of(context), status).bg;
    }
    return WmsBadgeColors.stockStatus(_fallbackColors(false), status).bg;
  }

  static IconData iconFor(String status) {
    switch (status) {
      case WmsStockStatuses.inStock:
        return Icons.check_circle_outline;
      case WmsStockStatuses.lowStock:
        return Icons.warning_amber_rounded;
      case WmsStockStatuses.outOfStock:
        return Icons.remove_shopping_cart_outlined;
      case WmsStockStatuses.expired:
        return Icons.event_busy_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = WmsBadgeColors.stockStatus(WmsUiColors.of(context), status);
    return _BadgeChip(
      label: status,
      background: palette.bg,
      foreground: palette.fg,
      compact: compact,
      icon: iconFor(status),
    );
  }
}

class WmsMovementTypeBadge extends StatelessWidget {
  const WmsMovementTypeBadge({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final palette = WmsBadgeColors.movementType(WmsUiColors.of(context), type);
    return _BadgeChip(
      label: WmsMovementTypes.label(type),
      background: palette.bg,
      foreground: palette.fg,
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.compact = false,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: compact ? 2 : AppSpacing.xs,
      ),
      decoration: WmsComponentStyles.badgeDecoration(
        foreground: foreground,
        background: background,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? WmsIconSizes.status - 4 : WmsIconSizes.status,
              color: foreground,
            ),
            SizedBox(width: compact ? 3 : 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic status chip for states with no domain badge of their own — Unread,
/// Draft, Syncing.
///
/// Exists so one-off chips stop being hand-rolled `Container`s with their own
/// radius and padding: every badge in the app now resolves to the same
/// [_BadgeChip] geometry, with a soft tint and high-contrast ink.
class WmsToneBadge extends StatelessWidget {
  const WmsToneBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.compact = false,
  });

  final String label;

  /// Semantic colour; the fill is derived from it as a soft tint.
  final Color color;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = WmsUiColors.of(context).isDark;

    return _BadgeChip(
      label: label,
      icon: icon,
      compact: compact,
      foreground: color,
      background: color.withValues(alpha: isDark ? 0.18 : 0.12),
    );
  }
}

/// Fallback palette when static badge helpers are used without context.
WmsUiColors _fallbackColors(bool isDark) =>
    isDark ? WmsUiColors.darkPalette() : WmsUiColors.lightPalette();
