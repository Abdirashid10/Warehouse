import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/supervisor_dashboard/domain/entities/supervisor_dashboard_data.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Compact inventory alerts — summary chips + top items only.
class SupervisorAlertsPanel extends StatelessWidget {
  const SupervisorAlertsPanel({
    super.key,
    required this.alerts,
    this.onViewAll,
  });

  final SupervisorInventoryAlerts alerts;
  final VoidCallback? onViewAll;

  static const _maxItemsPerGroup = 2;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      title: 'Alerts',
      count: alerts.hasAlerts
          ? alerts.lowStockCount +
              alerts.expiringCount +
              alerts.criticalCount
          : null,
      actionLabel: alerts.hasAlerts ? 'View all' : null,
      onAction: alerts.hasAlerts ? onViewAll : null,
      child: !alerts.hasAlerts
          ? AppCard(
              elevated: true,
              child: const WmsEmptyState(
                title: 'All clear',
                message: 'No inventory warnings right now.',
                icon: Icons.verified_outlined,
              ),
            )
          : AppCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (alerts.lowStock.isNotEmpty || alerts.lowStockCount > 0)
                        _AlertChip(
                          label: 'Low stock',
                          count: alerts.lowStockCount > 0
                              ? alerts.lowStockCount
                              : alerts.lowStock.length,
                          color: AppColors.warning,
                          icon: Icons.trending_down_rounded,
                        ),
                      if (alerts.expiring.isNotEmpty || alerts.expiringCount > 0)
                        _AlertChip(
                          label: 'Expiring',
                          count: alerts.expiringCount > 0
                              ? alerts.expiringCount
                              : alerts.expiring.length,
                          color: AppColors.warning,
                          icon: Icons.schedule_rounded,
                        ),
                      if (alerts.critical.isNotEmpty || alerts.criticalCount > 0)
                        _AlertChip(
                          label: 'Critical',
                          count: alerts.criticalCount > 0
                              ? alerts.criticalCount
                              : alerts.critical.length,
                          color: AppColors.error,
                          icon: Icons.error_outline_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._visibleItems(alerts.lowStock, AppColors.warning),
                  ..._visibleItems(alerts.expiring, AppColors.warning),
                  ..._visibleItems(alerts.critical, AppColors.error),
                ],
              ),
            ),
    );
  }

  List<Widget> _visibleItems(
    List<SupervisorInventoryAlertItem> items,
    Color accent,
  ) {
    if (items.isEmpty) return const [];
    return [
      for (var i = 0; i < items.length && i < _maxItemsPerGroup; i++) ...[
        if (i > 0)
          Divider(
            height: AppSpacing.lg,
            color: AppColors.border.withValues(alpha: 0.6),
          ),
        _CompactAlertRow(item: items[i], accent: accent),
      ],
    ];
  }
}

class _AlertChip extends StatelessWidget {
  const _AlertChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: WmsIconSizes.status, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAlertRow extends StatelessWidget {
  const _CompactAlertRow({required this.item, required this.accent});

  final SupervisorInventoryAlertItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.sku} · ${item.warehouseName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (item.quantity != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'Qty ${item.quantity}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal warehouse cards — less vertical scroll on mobile.
class SupervisorWarehouseStrip extends StatelessWidget {
  const SupervisorWarehouseStrip({super.key, required this.warehouses});

  final List<SupervisorWarehouseOverview> warehouses;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      title: 'Warehouse Overview',
      count: warehouses.isEmpty ? null : warehouses.length,
      child: warehouses.isEmpty
          ? AppCard(
              elevated: true,
              child: const WmsEmptyState(
                title: 'No warehouses',
                message: 'Assigned warehouse data will appear here.',
                icon: Icons.warehouse_outlined,
              ),
            )
          : SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: warehouses.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final w = warehouses[index];
                  return SizedBox(
                    width: 232,
                    child: _CompactWarehouseCard(warehouse: w),
                  );
                },
              ),
            ),
    );
  }
}

class _CompactWarehouseCard extends StatelessWidget {
  const _CompactWarehouseCard({required this.warehouse});

  final SupervisorWarehouseOverview warehouse;

  @override
  Widget build(BuildContext context) {
    final isHighLoad = warehouse.status.toLowerCase().contains('high');
    final statusColor = isHighLoad ? AppColors.warning : AppColors.success;
    final utilization = warehouse.utilizationPercent ?? 0;
    final capacityColor = utilization >= 85
        ? AppColors.warning
        : utilization >= 60
            ? AppColors.info
            : AppColors.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.warehouse_outlined,
                  size: WmsIconSizes.status,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  warehouse.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  warehouse.status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _MiniStat(
                icon: Icons.inventory_2_outlined,
                value: WmsFormatters.quantity(warehouse.stockCount),
                label: 'Units',
              ),
              const SizedBox(width: AppSpacing.sm),
              _MiniStat(
                icon: Icons.people_outline,
                value: '${warehouse.activeStaffCount}',
                label: 'Staff',
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'Capacity used',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                    
                    ),
              ),
              const Spacer(),
              Text(
                '$utilization%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: capacityColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (utilization / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.surfaceVariant,
              color: capacityColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Icon(icon, size: WmsIconSizes.status, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                    
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
