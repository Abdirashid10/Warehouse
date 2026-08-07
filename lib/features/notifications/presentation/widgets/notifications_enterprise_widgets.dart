import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/theme/app_theme_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_enterprise_primitives.dart';

abstract final class NotificationUi {
  static const sectionGap = WmsDesignTokens.sectionGap;

  static NotificationCategoryFilter categoryFor(AppNotification notification) {
    for (final category in NotificationCategoryFilter.values) {
      if (category == NotificationCategoryFilter.all) continue;
      if (NotificationsListState.matchesCategory(notification, category)) {
        return category;
      }
    }
    return NotificationCategoryFilter.system;
  }

  static String moduleLabel(NotificationCategoryFilter category) =>
      categoryLabel(category);

  static String categoryLabel(NotificationCategoryFilter category) {
    switch (category) {
      case NotificationCategoryFilter.all:
        return 'All';
      case NotificationCategoryFilter.inventory:
        return 'Inventory';
      case NotificationCategoryFilter.orders:
        return 'Orders';
      case NotificationCategoryFilter.tasks:
        return 'Tasks';
      case NotificationCategoryFilter.warehouses:
        return 'Warehouses';
      case NotificationCategoryFilter.system:
        return 'System';
    }
  }

  static String displayCategoryLabel(NotificationDisplayCategory category) {
    switch (category) {
      case NotificationDisplayCategory.all:
        return 'All';
      case NotificationDisplayCategory.inventoryAlerts:
        return 'Inventory';
      case NotificationDisplayCategory.lowStock:
        return 'Low Stock';
      case NotificationDisplayCategory.expiry:
        return 'Expiry';
      case NotificationDisplayCategory.taskUpdates:
        return 'Tasks';
      case NotificationDisplayCategory.orderUpdates:
        return 'Orders';
      case NotificationDisplayCategory.warehouseEvents:
        return 'Warehouse';
      case NotificationDisplayCategory.system:
        return 'System';
    }
  }

  static IconData categoryIcon(NotificationCategoryFilter category) {
    switch (category) {
      case NotificationCategoryFilter.all:
        return Icons.notifications_outlined;
      case NotificationCategoryFilter.inventory:
        return Icons.inventory_2_outlined;
      case NotificationCategoryFilter.orders:
        return Icons.shopping_cart_outlined;
      case NotificationCategoryFilter.tasks:
        return Icons.assignment_outlined;
      case NotificationCategoryFilter.warehouses:
        return Icons.warehouse_outlined;
      case NotificationCategoryFilter.system:
        return Icons.settings_suggest_outlined;
    }
  }

  static IconData displayCategoryIcon(NotificationDisplayCategory category) {
    switch (category) {
      case NotificationDisplayCategory.all:
        return Icons.notifications_outlined;
      case NotificationDisplayCategory.inventoryAlerts:
        return Icons.inventory_2_outlined;
      case NotificationDisplayCategory.lowStock:
        return Icons.trending_down_rounded;
      case NotificationDisplayCategory.expiry:
        return Icons.event_busy_outlined;
      case NotificationDisplayCategory.taskUpdates:
        return Icons.assignment_outlined;
      case NotificationDisplayCategory.orderUpdates:
        return Icons.shopping_cart_outlined;
      case NotificationDisplayCategory.warehouseEvents:
        return Icons.warehouse_outlined;
      case NotificationDisplayCategory.system:
        return Icons.settings_suggest_outlined;
    }
  }

  static Color categoryColor(NotificationCategoryFilter category, WmsUiColors colors) {
    switch (category) {
      case NotificationCategoryFilter.all:
        return colors.primary;
      case NotificationCategoryFilter.inventory:
        return colors.warning;
      case NotificationCategoryFilter.orders:
        return colors.info;
      case NotificationCategoryFilter.tasks:
        return const Color(0xFF7C3AED);
      case NotificationCategoryFilter.warehouses:
        return colors.accent;
      case NotificationCategoryFilter.system:
        return AppThemeColors.lightTextSecondary;
    }
  }

  static bool matchesDisplayCategory(
    AppNotification n,
    NotificationDisplayCategory category,
  ) {
    if (category == NotificationDisplayCategory.all) return true;
    final text = '${n.title} ${n.message} ${n.type}'.toLowerCase();
    switch (category) {
      case NotificationDisplayCategory.lowStock:
        return text.contains('low stock') || text.contains('low-stock');
      case NotificationDisplayCategory.expiry:
        return text.contains('expir');
      case NotificationDisplayCategory.inventoryAlerts:
        return (text.contains('inventory') ||
                text.contains('stock') ||
                text.contains('low stock')) &&
            !text.contains('expir');
      case NotificationDisplayCategory.taskUpdates:
        return text.contains('task');
      case NotificationDisplayCategory.orderUpdates:
        return text.contains('order');
      case NotificationDisplayCategory.warehouseEvents:
        return text.contains('warehouse') ||
            text.contains('location') ||
            text.contains('capacity');
      case NotificationDisplayCategory.system:
        return !matchesDisplayCategory(n, NotificationDisplayCategory.inventoryAlerts) &&
            !matchesDisplayCategory(n, NotificationDisplayCategory.lowStock) &&
            !matchesDisplayCategory(n, NotificationDisplayCategory.expiry) &&
            !matchesDisplayCategory(n, NotificationDisplayCategory.taskUpdates) &&
            !matchesDisplayCategory(n, NotificationDisplayCategory.orderUpdates) &&
            !matchesDisplayCategory(n, NotificationDisplayCategory.warehouseEvents);
      case NotificationDisplayCategory.all:
        return true;
    }
  }

  static NotificationPriority priorityFor(AppNotification n) {
    final text = '${n.title} ${n.message} ${n.type}'.toLowerCase();
    if (text.contains('critical') ||
        text.contains('out of stock') ||
        text.contains('expired') ||
        text.contains('failure')) {
      return NotificationPriority.critical;
    }
    if (text.contains('urgent') ||
        text.contains('high') ||
        text.contains('overdue')) {
      return NotificationPriority.high;
    }
    if (text.contains('low stock') ||
        text.contains('warning') ||
        text.contains('expir')) {
      return NotificationPriority.medium;
    }
    return NotificationPriority.low;
  }

  static Color priorityColor(NotificationPriority priority, WmsUiColors colors) {
    switch (priority) {
      case NotificationPriority.critical:
        return colors.error;
      case NotificationPriority.high:
        return colors.warning;
      case NotificationPriority.medium:
        return colors.info;
      case NotificationPriority.low:
        return AppThemeColors.lightTextSecondary;
    }
  }

  static String priorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return 'Critical';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.low:
        return 'Low';
    }
  }

  static NotificationTimeGroup timeGroupFor(DateTime? createdAt) {
    if (createdAt == null) return NotificationTimeGroup.older;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (day == today) return NotificationTimeGroup.today;
    if (day == today.subtract(const Duration(days: 1))) {
      return NotificationTimeGroup.yesterday;
    }
    if (day.isAfter(today.subtract(const Duration(days: 7)))) {
      return NotificationTimeGroup.thisWeek;
    }
    return NotificationTimeGroup.older;
  }

  static String timeGroupLabel(NotificationTimeGroup group) {
    switch (group) {
      case NotificationTimeGroup.today:
        return 'Today';
      case NotificationTimeGroup.yesterday:
        return 'Yesterday';
      case NotificationTimeGroup.thisWeek:
        return 'This Week';
      case NotificationTimeGroup.older:
        return 'Older';
    }
  }
}

enum NotificationDisplayCategory {
  all,
  inventoryAlerts,
  lowStock,
  expiry,
  taskUpdates,
  orderUpdates,
  warehouseEvents,
  system,
}

enum NotificationPriority { critical, high, medium, low }

enum NotificationTimeGroup { today, yesterday, thisWeek, older }

abstract final class NotificationMetrics {
  static int criticalCount(NotificationsListState data) =>
      data.items.where((n) => NotificationUi.priorityFor(n) == NotificationPriority.critical).length;

  static int alertsToday(NotificationsListState data) {
    final now = DateTime.now();
    return data.items.where((n) {
      final c = n.createdAt;
      return c != null &&
          c.year == now.year &&
          c.month == now.month &&
          c.day == now.day;
    }).length;
  }

  static int inventoryWarnings(NotificationsListState data) =>
      data.items.where((n) {
        final text = '${n.title} ${n.message}'.toLowerCase();
        return text.contains('inventory') ||
            text.contains('stock') ||
            text.contains('low stock');
      }).length;

  static int expiredProducts(NotificationsListState data) =>
      data.items.where((n) {
        final text = '${n.title} ${n.message}'.toLowerCase();
        return text.contains('expir');
      }).length;

  static Map<NotificationTimeGroup, List<AppNotification>> groupByTime(
    Iterable<AppNotification> items,
  ) {
    final map = {
      for (final g in NotificationTimeGroup.values) g: <AppNotification>[],
    };
    for (final n in items) {
      map[NotificationUi.timeGroupFor(n.createdAt)]!.add(n);
    }
    return map;
  }

  static ({
    int critical,
    int high,
    int medium,
    int low,
  }) severityBreakdown(Iterable<AppNotification> items) {
    var critical = 0;
    var high = 0;
    var medium = 0;
    var low = 0;
    for (final n in items) {
      switch (NotificationUi.priorityFor(n)) {
        case NotificationPriority.critical:
          critical++;
        case NotificationPriority.high:
          high++;
        case NotificationPriority.medium:
          medium++;
        case NotificationPriority.low:
          low++;
      }
    }
    return (critical: critical, high: high, medium: medium, low: low);
  }

  static List<AppNotification> criticalAlerts(NotificationsListState data) =>
      data.items
          .where((n) => NotificationUi.priorityFor(n) == NotificationPriority.critical)
          .toList();
}

/// Sort for command-center display: severity → unread → newest.
List<AppNotification> sortNotificationsForDisplay(
  List<AppNotification> items,
  NotificationsListState data,
) {
  final sorted = [...items];
  sorted.sort((a, b) {
    final pa = NotificationUi.priorityFor(a).index;
    final pb = NotificationUi.priorityFor(b).index;
    if (pa != pb) return pa.compareTo(pb);
    final readA = data.isRead(a);
    final readB = data.isRead(b);
    if (readA != readB) return readA ? 1 : -1;
    final ca = a.createdAt;
    final cb = b.createdAt;
    if (ca == null && cb == null) return 0;
    if (ca == null) return 1;
    if (cb == null) return -1;
    return cb.compareTo(ca);
  });
  return sorted;
}

class NotificationsCommandCenterHeader extends StatelessWidget {
  const NotificationsCommandCenterHeader({
    super.key,
    required this.data,
    required this.onMarkAllRead,
  });

  final NotificationsListState data;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final unread = data.effectiveUnreadCount;

    return WmsExecutiveHeaderShell(
      title: 'Operations monitoring center',
      trailing: unread > 0
          ? FilledButton.tonal(
              onPressed: data.items.isEmpty ? null : onMarkAllRead,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
              child: const Text('Mark all read'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WmsDashboardSection(
            title: 'Alert Summary',
            count: data.items.length,
            child: WmsKpiGrid(
              children: [
                WmsKpiTile(
                  label: 'Total Alerts',
                  value: '${data.items.length}',
                  icon: Icons.notifications_outlined,
                  color: colors.primary,
                ),
                WmsKpiTile(
                  label: 'Unread',
                  value: '$unread',
                  icon: Icons.mark_email_unread_outlined,
                  color: unread > 0 ? colors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                WmsKpiTile(
                  label: 'Critical',
                  value: '${NotificationMetrics.criticalCount(data)}',
                  icon: Icons.error_outline_rounded,
                  color: colors.error,
                ),
                WmsKpiTile(
                  label: 'Alerts Today',
                  value: '${NotificationMetrics.alertsToday(data)}',
                  icon: Icons.today_outlined,
                  color: colors.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          NotificationsSeverityBar(items: data.items),
          const SizedBox(height: AppSpacing.sm),
          NotificationsModuleStrip(data: data),
        ],
      ),
    );
  }
}

/// Back-compat alias for embedded shell header.
typedef NotificationsExecutiveHeader = NotificationsCommandCenterHeader;

/// SOC-style severity distribution bar.
class NotificationsSeverityBar extends StatelessWidget {
  const NotificationsSeverityBar({super.key, required this.items});

  final List<AppNotification> items;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final wms = context.wms;
    final breakdown = NotificationMetrics.severityBreakdown(items);
    final total =
        breakdown.critical + breakdown.high + breakdown.medium + breakdown.low;
    if (total == 0) return const SizedBox.shrink();

    int flex(int count) => count == 0 ? 0 : count;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Alert Severity',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                '$total active',
                style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: wms.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (breakdown.critical > 0)
                    Expanded(
                      flex: flex(breakdown.critical),
                      child: ColoredBox(
                        color: NotificationUi.priorityColor(
                          NotificationPriority.critical,
                          colors,
                        ),
                      ),
                    ),
                  if (breakdown.high > 0)
                    Expanded(
                      flex: flex(breakdown.high),
                      child: ColoredBox(
                        color: NotificationUi.priorityColor(
                          NotificationPriority.high,
                          colors,
                        ),
                      ),
                    ),
                  if (breakdown.medium > 0)
                    Expanded(
                      flex: flex(breakdown.medium),
                      child: ColoredBox(
                        color: NotificationUi.priorityColor(
                          NotificationPriority.medium,
                          colors,
                        ),
                      ),
                    ),
                  if (breakdown.low > 0)
                    Expanded(
                      flex: flex(breakdown.low),
                      child: ColoredBox(
                        color: NotificationUi.priorityColor(
                          NotificationPriority.low,
                          colors,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _SeverityLegend(
                priority: NotificationPriority.critical,
                count: breakdown.critical,
              ),
              _SeverityLegend(
                priority: NotificationPriority.high,
                count: breakdown.high,
              ),
              _SeverityLegend(
                priority: NotificationPriority.medium,
                count: breakdown.medium,
              ),
              _SeverityLegend(
                priority: NotificationPriority.low,
                count: breakdown.low,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeverityLegend extends StatelessWidget {
  const _SeverityLegend({required this.priority, required this.count});

  final NotificationPriority priority;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final color = NotificationUi.priorityColor(priority, colors);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 4),
        Text(
          '${NotificationUi.priorityLabel(priority)} $count',
          style: WmsDesignTokens.supportingDense(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// Module-level alert counts for executive visibility.
class NotificationsModuleStrip extends StatelessWidget {
  const NotificationsModuleStrip({super.key, required this.data});

  final NotificationsListState data;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModuleStat(
              label: 'Inventory',
              count: data.inventoryItems.length,
              unread: data.unreadFor(NotificationCategoryFilter.inventory),
              color: colors.warning,
              icon: Icons.inventory_2_outlined,
            ),
          ),
          _ModuleDivider(),
          Expanded(
            child: _ModuleStat(
              label: 'Tasks',
              count: data.taskItems.length,
              unread: data.unreadFor(NotificationCategoryFilter.tasks),
              color: const Color(0xFF7C3AED),
              icon: Icons.assignment_outlined,
            ),
          ),
          _ModuleDivider(),
          Expanded(
            child: _ModuleStat(
              label: 'Orders',
              count: data.orderItems.length,
              unread: data.unreadFor(NotificationCategoryFilter.orders),
              color: colors.info,
              icon: Icons.shopping_cart_outlined,
            ),
          ),
          _ModuleDivider(),
          Expanded(
            child: _ModuleStat(
              label: 'Warehouse',
              count: data.warehouseItems.length,
              unread: data.unreadFor(NotificationCategoryFilter.warehouses),
              color: colors.accent,
              icon: Icons.warehouse_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: context.wms.divider,
    );
  }
}

class _ModuleStat extends StatelessWidget {
  const _ModuleStat({
    required this.label,
    required this.count,
    required this.unread,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final int unread;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: WmsIconSizes.status, color: color),
            if (unread > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    textAlign: TextAlign.center,
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
              ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WmsDesignTokens.supportingDense(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class NotificationsFilterPanel extends StatelessWidget {
  const NotificationsFilterPanel({
    super.key,
    required this.displayCategory,
    required this.priority,
    required this.data,
    required this.onCategorySelected,
    required this.onPrioritySelected,
    required this.unreadOnly,
    required this.onUnreadOnlyChanged,
  });

  final NotificationDisplayCategory displayCategory;
  final NotificationPriority? priority;
  final NotificationsListState data;
  final ValueChanged<NotificationDisplayCategory> onCategorySelected;
  final ValueChanged<NotificationPriority?> onPrioritySelected;
  final bool unreadOnly;
  final ValueChanged<bool> onUnreadOnlyChanged;

  static const _categories = [
    NotificationDisplayCategory.all,
    NotificationDisplayCategory.inventoryAlerts,
    NotificationDisplayCategory.lowStock,
    NotificationDisplayCategory.expiry,
    NotificationDisplayCategory.taskUpdates,
    NotificationDisplayCategory.orderUpdates,
    NotificationDisplayCategory.warehouseEvents,
    NotificationDisplayCategory.system,
  ];
  static const _priorities = NotificationPriority.values;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final wms = context.wms;
    final unread = data.effectiveUnreadCount;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filters',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              FilterChip(
                label: Text(
                  'Unread ($unread)',
                  style: WmsDesignTokens.body(context),
                ),
                selected: unreadOnly,
                onSelected: onUnreadOnlyChanged,
                showCheckmark: false,
                avatar: Icon(
                  Icons.mark_email_unread_outlined,
                  size: WmsIconSizes.status,
                  color: unreadOnly ? colors.primary : wms.textSecondary,
                ),
                selectedColor: colors.primaryMuted,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _categories.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  WmsEnterpriseFilterChip(
                    label: NotificationUi.displayCategoryLabel(_categories[i]),
                    icon: NotificationUi.displayCategoryIcon(_categories[i]),
                    selected: displayCategory == _categories[i],
                    onTap: () => onCategorySelected(_categories[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                WmsEnterpriseFilterChip(
                  label: 'All priorities',
                  selected: priority == null,
                  onTap: () => onPrioritySelected(null),
                ),
                for (final p in _priorities) ...[
                  const SizedBox(width: AppSpacing.xs),
                  WmsEnterpriseFilterChip(
                    label: NotificationUi.priorityLabel(p),
                    color: NotificationUi.priorityColor(p, colors),
                    selected: priority == p,
                    onTap: () => onPrioritySelected(priority == p ? null : p),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsEnterpriseCard extends StatelessWidget {
  const NotificationsEnterpriseCard({
    super.key,
    required this.notification,
    required this.isRead,
    required this.onTap,
    required this.onMarkRead,
    required this.onArchive,
  });

  final AppNotification notification;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final wms = context.wms;
    final module = NotificationUi.categoryFor(notification);
    final priority = NotificationUi.priorityFor(notification);
    final priorityColor = NotificationUi.priorityColor(priority, colors);
    final moduleColor = NotificationUi.categoryColor(module, colors);

    return AppCard(
      onTap: onTap,
      elevated: true,
      accentColor: isRead ? null : priorityColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  NotificationUi.categoryIcon(module),
                  size: WmsIconSizes.status,
                  color: moduleColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                          ),
                        ),
                        _PriorityBadge(priority: priority),
                      ],
                    ),
                    if (notification.message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WmsDesignTokens.body(context).copyWith(
                              color: wms.textSecondary,
                              height: 1.2,
                            ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          NotificationUi.moduleLabel(module),
                          style: WmsDesignTokens.supportingDense(context).copyWith(
                                color: moduleColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          WmsFormatters.notificationTimestamp(
                            notification.createdAt,
                          ),
                          style: WmsDesignTokens.supportingDense(context).copyWith(
                                color: wms.textTertiary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isRead) ...[
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              WmsCardAction(
                icon: isRead
                    ? Icons.drafts_outlined
                    : Icons.mark_email_read_outlined,
                label: isRead ? 'Read' : 'Mark read',
                onTap: onMarkRead,
              ),
              WmsCardAction(
                icon: Icons.visibility_outlined,
                label: 'Details',
                onTap: onTap,
              ),
              WmsCardAction(
                icon: Icons.archive_outlined,
                label: 'Archive',
                onTap: onArchive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final NotificationPriority priority;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final color = NotificationUi.priorityColor(priority, colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        NotificationUi.priorityLabel(priority),
        style: WmsDesignTokens.supportingDense(context).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class NotificationsTimeGroupSection extends StatelessWidget {
  const NotificationsTimeGroupSection({
    super.key,
    required this.group,
    required this.items,
    required this.data,
    required this.onRead,
    required this.onArchive,
  });

  final NotificationTimeGroup group;
  final List<AppNotification> items;
  final NotificationsListState data;
  final ValueChanged<AppNotification> onRead;
  final ValueChanged<AppNotification> onArchive;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Text(
                NotificationUi.timeGroupLabel(group),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${items.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                ),
              ),
            ],
          ),
        ),
        for (final n in sortNotificationsForDisplay(items, data))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: NotificationsEnterpriseCard(
              notification: n,
              isRead: data.isRead(n),
              onTap: () => onRead(n),
              onMarkRead: () => onRead(n),
              onArchive: () => onArchive(n),
            ),
          ),
      ],
    );
  }
}

class NotificationsCriticalSection extends StatelessWidget {
  const NotificationsCriticalSection({
    super.key,
    required this.items,
    required this.data,
    required this.onRead,
    required this.onArchive,
  });

  final List<AppNotification> items;
  final NotificationsListState data;
  final ValueChanged<AppNotification> onRead;
  final ValueChanged<AppNotification> onArchive;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final sorted = sortNotificationsForDisplay(items, data);

    return WmsDashboardSection(
      title: 'Critical Alerts',
      subtitle: 'Requires immediate attention',
      count: sorted.length,
      child: Column(
        children: [
          for (final n in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: NotificationsEnterpriseCard(
                notification: n,
                isRead: data.isRead(n),
                onTap: () => onRead(n),
                onMarkRead: () => onRead(n),
                onArchive: () => onArchive(n),
              ),
            ),
        ],
      ),
    );
  }
}

class NotificationsEnterpriseSection extends StatelessWidget {
  const NotificationsEnterpriseSection({
    super.key,
    required this.title,
    required this.category,
    required this.items,
    required this.data,
    required this.onRead,
    this.onArchive,
    this.subtitle,
  });

  final String title;
  final NotificationCategoryFilter category;
  final List<AppNotification> items;
  final NotificationsListState data;
  final ValueChanged<AppNotification> onRead;
  final ValueChanged<AppNotification>? onArchive;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    if (items.isEmpty) return const SizedBox.shrink();

    final sorted = sortNotificationsForDisplay(items, data);
    final unread = sorted.where((n) => !data.isRead(n)).length;
    final color = NotificationUi.categoryColor(category, colors);

    return WmsDashboardSection(
      title: title,
      subtitle: subtitle ?? (unread > 0 ? '$unread unread' : null),
      count: sorted.length,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                NotificationUi.categoryIcon(category),
                size: WmsIconSizes.status,
                color: color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: sorted.isEmpty
                        ? 0
                        : unread / sorted.length,
                    minHeight: 3,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final n in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: NotificationsEnterpriseCard(
                notification: n,
                isRead: data.isRead(n),
                onTap: () => onRead(n),
                onMarkRead: () => onRead(n),
                onArchive: () => (onArchive ?? (_) {}).call(n),
              ),
            ),
        ],
      ),
    );
  }
}

/// Applies UI-only category and priority filters (no cubit changes).
List<AppNotification> filterNotificationsForDisplay({
  required NotificationsListState data,
  required NotificationDisplayCategory displayCategory,
  required NotificationPriority? priority,
  required Set<String> archivedIds,
  bool unreadOnly = false,
}) {
  return data.items.where((n) {
    if (archivedIds.contains(n.id)) return false;
    if (unreadOnly && data.isRead(n)) return false;
    if (!NotificationUi.matchesDisplayCategory(n, displayCategory)) {
      return false;
    }
    if (priority != null && NotificationUi.priorityFor(n) != priority) {
      return false;
    }
    return true;
  }).toList();
}
