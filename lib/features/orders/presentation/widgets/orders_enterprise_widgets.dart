import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_enterprise_primitives.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';

abstract final class OrdersUi {
  static const sectionGap = WmsDesignTokens.sectionGap;
  static const cancelledStatus = 'Cancelled';

  static const filterStatuses = [
    WmsOrderStatuses.pending,
    WmsOrderStatuses.processing,
    WmsOrderStatuses.packed,
    WmsOrderStatuses.shipped,
    WmsOrderStatuses.delivered,
    cancelledStatus,
  ];

  static String dateFilterLabel(OrdersDateFilter filter) {
    switch (filter) {
      case OrdersDateFilter.all:
        return 'All Dates';
      case OrdersDateFilter.today:
        return 'Today';
      case OrdersDateFilter.week:
        return 'This Week';
      case OrdersDateFilter.month:
        return 'This Month';
      case OrdersDateFilter.year:
        return 'This Year';
    }
  }

  static Color statusAccent(String status) =>
      WmsOrderStatusBadge.foregroundFor(status);

  static bool isCancelled(String status) =>
      status.toLowerCase() == cancelledStatus.toLowerCase();

  static const lifecycleSteps = WmsOrderStatuses.all;

  static int lifecycleIndex(String status) {
    if (isCancelled(status)) return -1;
    final i = lifecycleSteps.indexOf(status);
    return i < 0 ? 0 : i;
  }
}

abstract final class OrdersMetrics {
  static int completedOrders(OrdersViewState data) => data.deliveredOrders;

  static int ordersToday(OrdersViewState data) {
    final now = DateTime.now();
    return data.orders.where((o) {
      final c = o.createdAt;
      return c != null &&
          c.year == now.year &&
          c.month == now.month &&
          c.day == now.day;
    }).length;
  }

  static int ordersThisWeek(OrdersViewState data) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    return data.orders
        .where((o) => o.createdAt != null && !o.createdAt!.isBefore(start))
        .length;
  }

  static int fulfillmentRate(OrdersViewState data) {
    if (data.totalOrders == 0) return 0;
    return ((data.deliveredOrders / data.totalOrders) * 100).round();
  }

  static String averageProcessingTime(OrdersViewState data) {
    final pipeline = data.orders.where(
      (o) =>
          o.status == WmsOrderStatuses.shipped ||
          o.status == WmsOrderStatuses.delivered ||
          o.status == WmsOrderStatuses.packed,
    );
    if (pipeline.isEmpty) return '—';
    var totalHours = 0;
    var count = 0;
    final now = DateTime.now();
    for (final o in pipeline) {
      final created = o.createdAt;
      if (created == null) continue;
      totalHours += now.difference(created).inHours.clamp(1, 9999);
      count++;
    }
    if (count == 0) return '—';
    final avg = totalHours / count;
    if (avg < 24) return '${avg.round()}h';
    return '${(avg / 24).toStringAsFixed(1)}d';
  }

  static List<MapEntry<String, double>> dailyTrend(OrdersViewState data) {
    final now = DateTime.now();
    final days = <String, double>{};
    for (var i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      days['${d.month}/${d.day}'] = 0;
    }
    for (final order in data.orders) {
      final c = order.createdAt;
      if (c == null) continue;
      final d = DateTime(c.year, c.month, c.day);
      final diff = now.difference(d).inDays;
      if (diff < 0 || diff > 6) continue;
      final key = '${d.month}/${d.day}';
      days[key] = (days[key] ?? 0) + 1;
    }
    return days.entries.toList();
  }

  static ({int thisWeek, int lastWeek}) weeklyPerformance(OrdersViewState data) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = today.subtract(const Duration(days: 6));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    var thisWeek = 0;
    var lastWeek = 0;
    for (final o in data.orders) {
      final c = o.createdAt;
      if (c == null) continue;
      final d = DateTime(c.year, c.month, c.day);
      if (!d.isBefore(thisWeekStart)) {
        thisWeek++;
      } else if (!d.isBefore(lastWeekStart) && d.isBefore(thisWeekStart)) {
        lastWeek++;
      }
    }
    return (thisWeek: thisWeek, lastWeek: lastWeek);
  }

  static List<MapEntry<String, double>> warehouseDistribution(
    OrdersViewState data,
  ) {
    final map = <String, double>{};
    for (final order in data.orders) {
      final wh = data.inferredWarehouse(order);
      map[wh] = (map[wh] ?? 0) + 1;
    }
    return map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  static int countForStatus(OrdersViewState data, String status) {
    if (status == OrdersUi.cancelledStatus) return data.cancelledOrders;
    return data.orders.where((o) => o.status == status).length;
  }

  static int inPipeline(OrdersViewState data) =>
      data.processingOrders +
      data.orders.where((o) => o.status == WmsOrderStatuses.packed).length +
      data.shippedOrders;

  static ({
    int pending,
    int processing,
    int packed,
    int shipped,
    int delivered,
    int cancelled,
  }) pipelineBreakdown(OrdersViewState data) {
    var processing = 0;
    var packed = 0;
    for (final order in data.orders) {
      switch (order.status) {
        case WmsOrderStatuses.processing:
          processing++;
        case WmsOrderStatuses.packed:
          packed++;
        default:
          break;
      }
    }
    return (
      pending: data.pendingOrders,
      processing: processing,
      packed: packed,
      shipped: data.shippedOrders,
      delivered: data.deliveredOrders,
      cancelled: data.cancelledOrders,
    );
  }
}

class OrdersExecutiveHeader extends StatelessWidget {
  const OrdersExecutiveHeader({
    super.key,
    required this.data,
    required this.isAdminWorkspace,
  });

  final OrdersViewState data;
  final bool isAdminWorkspace;

  @override
  Widget build(BuildContext context) {
    return WmsExecutiveHeaderShell(
      title: isAdminWorkspace
          ? 'Enterprise order control'
          : 'Order fulfillment center',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WmsDashboardSection(
            title: 'Executive Summary',
            count: data.totalOrders,
            child: WmsKpiGrid(
              children: [
                WmsKpiTile(
                  label: 'Total Orders',
                  value: '${data.totalOrders}',
                  icon: Icons.shopping_cart_outlined,
                  color: AppColors.primary,
                ),
                WmsKpiTile(
                  label: 'Pending',
                  value: '${data.pendingOrders}',
                  icon: Icons.schedule_outlined,
                  color: AppColors.warning,
                ),
                WmsKpiTile(
                  label: 'In Pipeline',
                  value: '${OrdersMetrics.inPipeline(data)}',
                  icon: Icons.sync_alt_rounded,
                  color: AppColors.info,
                ),
                WmsKpiTile(
                  label: 'Delivered',
                  value: '${data.deliveredOrders}',
                  icon: Icons.task_alt_outlined,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OrdersPipelineBar(data: data),
          const SizedBox(height: AppSpacing.sm),
          OrdersOperationalStrip(data: data),
        ],
      ),
    );
  }
}

/// SAP-style order pipeline visualization across lifecycle stages.
class OrdersPipelineBar extends StatelessWidget {
  const OrdersPipelineBar({super.key, required this.data});

  final OrdersViewState data;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final breakdown = OrdersMetrics.pipelineBreakdown(data);
    final total = breakdown.pending +
        breakdown.processing +
        breakdown.packed +
        breakdown.shipped +
        breakdown.delivered +
        breakdown.cancelled;
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
                'Order Pipeline',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                '$total orders',
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
                  if (breakdown.pending > 0)
                    Expanded(
                      flex: flex(breakdown.pending),
                      child: ColoredBox(
                        color: WmsOrderStatusBadge.foregroundFor(
                          WmsOrderStatuses.pending,
                        ),
                      ),
                    ),
                  if (breakdown.processing > 0)
                    Expanded(
                      flex: flex(breakdown.processing),
                      child: ColoredBox(
                        color: WmsOrderStatusBadge.foregroundFor(
                          WmsOrderStatuses.processing,
                        ),
                      ),
                    ),
                  if (breakdown.packed > 0)
                    Expanded(
                      flex: flex(breakdown.packed),
                      child: ColoredBox(
                        color: WmsOrderStatusBadge.foregroundFor(
                          WmsOrderStatuses.packed,
                        ),
                      ),
                    ),
                  if (breakdown.shipped > 0)
                    Expanded(
                      flex: flex(breakdown.shipped),
                      child: ColoredBox(
                        color: WmsOrderStatusBadge.foregroundFor(
                          WmsOrderStatuses.shipped,
                        ),
                      ),
                    ),
                  if (breakdown.delivered > 0)
                    Expanded(
                      flex: flex(breakdown.delivered),
                      child: ColoredBox(
                        color: WmsOrderStatusBadge.foregroundFor(
                          WmsOrderStatuses.delivered,
                        ),
                      ),
                    ),
                  if (breakdown.cancelled > 0)
                    Expanded(
                      flex: flex(breakdown.cancelled),
                      child: const ColoredBox(color: AppColors.error),
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
              _PipelineLegend(
                color: WmsOrderStatusBadge.foregroundFor(WmsOrderStatuses.pending),
                label: 'Pending',
                count: breakdown.pending,
              ),
              _PipelineLegend(
                color: WmsOrderStatusBadge.foregroundFor(WmsOrderStatuses.processing),
                label: 'Processing',
                count: breakdown.processing,
              ),
              _PipelineLegend(
                color: WmsOrderStatusBadge.foregroundFor(WmsOrderStatuses.packed),
                label: 'Packed',
                count: breakdown.packed,
              ),
              _PipelineLegend(
                color: WmsOrderStatusBadge.foregroundFor(WmsOrderStatuses.shipped),
                label: 'Shipped',
                count: breakdown.shipped,
              ),
              _PipelineLegend(
                color: WmsOrderStatusBadge.foregroundFor(WmsOrderStatuses.delivered),
                label: 'Delivered',
                count: breakdown.delivered,
              ),
              if (breakdown.cancelled > 0)
                _PipelineLegend(
                  color: AppColors.error,
                  label: 'Cancelled',
                  count: breakdown.cancelled,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipelineLegend extends StatelessWidget {
  const _PipelineLegend({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 4),
        Text(
          '$label $count',
          style: WmsDesignTokens.supportingDense(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// Compact operational KPI strip for floor supervisors.
class OrdersOperationalStrip extends StatelessWidget {
  const OrdersOperationalStrip({super.key, required this.data});

  final OrdersViewState data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _OpStat(
              label: 'Today',
              value: '${OrdersMetrics.ordersToday(data)}',
              icon: Icons.today_outlined,
              color: AppColors.primary,
            ),
          ),
          _OpDivider(),
          Expanded(
            child: _OpStat(
              label: 'This Week',
              value: '${OrdersMetrics.ordersThisWeek(data)}',
              icon: Icons.date_range_outlined,
              color: AppColors.info,
            ),
          ),
          _OpDivider(),
          Expanded(
            child: _OpStat(
              label: 'Fulfillment',
              value: '${OrdersMetrics.fulfillmentRate(data)}%',
              icon: Icons.verified_outlined,
              color: AppColors.success,
            ),
          ),
          _OpDivider(),
          Expanded(
            child: _OpStat(
              label: 'Avg Process',
              value: OrdersMetrics.averageProcessingTime(data),
              icon: Icons.timer_outlined,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: context.wms.divider,
    );
  }
}

class _OpStat extends StatelessWidget {
  const _OpStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: WmsIconSizes.status, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

class OrdersTabBar extends StatelessWidget implements PreferredSizeWidget {
  const OrdersTabBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final wms = context.wms;
    final compact = MediaQuery.sizeOf(context).width <= MobileUi.compactWidth;

    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: wms.border.withValues(alpha: 0.5),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primary, width: 2.5),
        borderRadius: BorderRadius.circular(2),
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
      unselectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: wms.textSecondary,
          ),
      tabs: [
        Tab(text: compact ? 'Orders' : 'Orders List'),
        Tab(text: compact ? 'Create' : 'Create Order'),
        const Tab(text: 'Analytics'),
        Tab(text: compact ? 'Alerts' : 'Notifications'),
      ],
    );
  }
}

class OrdersFilterPanel extends StatelessWidget {
  const OrdersFilterPanel({
    super.key,
    required this.data,
    required this.searchController,
    required this.onSearch,
    required this.onWarehouseFilter,
    required this.onDateFilter,
    this.onStatusFilter,
  });

  final OrdersViewState data;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onWarehouseFilter;
  final ValueChanged<OrdersDateFilter> onDateFilter;
  final ValueChanged<String?>? onStatusFilter;

  static const _dateFilters = OrdersDateFilter.values;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;

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
          SearchBar(
            controller: searchController,
            hintText: 'Order #, customer, warehouse…',
            onChanged: onSearch,
            leading: Icon(Icons.search, size: WmsIconSizes.search),
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(wms.surfaceVariant),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            constraints: const BoxConstraints(minHeight: 40),
            textStyle: WidgetStatePropertyAll(
              Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (onStatusFilter != null) ...[
            const SizedBox(height: AppSpacing.sm),
            OrdersStatusChipBar(
              data: data,
              onStatusFilter: onStatusFilter!,
            ),
          ],
          if (data.warehouses.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _OrdersFilterChip(
                    label: 'All warehouses',
                    selected: data.warehouseFilter == null,
                    onTap: () => onWarehouseFilter(null),
                  ),
                  for (final warehouse in data.warehouses) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _OrdersFilterChip(
                      label: warehouse,
                      selected: data.warehouseFilter == warehouse,
                      icon: Icons.warehouse_outlined,
                      onTap: () => onWarehouseFilter(warehouse),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _dateFilters.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  _OrdersFilterChip(
                    label: OrdersUi.dateFilterLabel(_dateFilters[i]),
                    selected: data.dateFilter == _dateFilters[i],
                    icon: Icons.calendar_today_outlined,
                    onTap: () => onDateFilter(_dateFilters[i]),
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

class OrdersStatusChipBar extends StatelessWidget {
  const OrdersStatusChipBar({
    super.key,
    required this.data,
    required this.onStatusFilter,
  });

  final OrdersViewState data;
  final ValueChanged<String?> onStatusFilter;

  @override
  Widget build(BuildContext context) {
    final selected = data.statusFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusCountChip(
            label: 'All',
            count: data.totalOrders,
            color: AppColors.primary,
            selected: selected == null || selected.isEmpty,
            onTap: () => onStatusFilter(null),
          ),
          for (final status in OrdersUi.filterStatuses) ...[
            const SizedBox(width: AppSpacing.xs),
            _StatusCountChip(
              label: status,
              count: OrdersMetrics.countForStatus(data, status),
              color: WmsOrderStatusBadge.foregroundFor(status),
              selected: selected == status,
              onTap: () => onStatusFilter(selected == status ? null : status),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCountChip extends StatelessWidget {
  const _StatusCountChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: WmsDesignTokens.body(context)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '$count',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: Icon(WmsOrderStatusBadge.iconFor(label), size: WmsIconSizes.status, color: color),
      selectedColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _OrdersFilterChip extends StatelessWidget {
  const _OrdersFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, maxLines: 1, softWrap: false),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: icon != null
          ? Icon(icon, size: WmsIconSizes.status, color: AppColors.primary)
          : null,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: WmsDesignTokens.body(context).copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
    );
  }
}

class OrdersCompactLifecycleStepper extends StatelessWidget {
  const OrdersCompactLifecycleStepper({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    if (OrdersUi.isCancelled(status)) {
      return Row(
        children: [
          Icon(Icons.cancel_outlined, size: WmsIconSizes.status, color: AppColors.error),
          const SizedBox(width: 4),
          Text(
            OrdersUi.cancelledStatus,
            style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      );
    }

    final current = OrdersUi.lifecycleIndex(status);

    return Row(
      children: [
        for (var i = 0; i < OrdersUi.lifecycleSteps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= current
                    ? OrdersUi.statusAccent(status).withValues(alpha: 0.35)
                    : context.wms.divider,
              ),
            ),
          _LifecycleDot(
            step: OrdersUi.lifecycleSteps[i],
            isComplete: i < current,
            isCurrent: i == current,
          ),
        ],
      ],
    );
  }
}

class _LifecycleDot extends StatelessWidget {
  const _LifecycleDot({
    required this.step,
    required this.isComplete,
    required this.isCurrent,
  });

  final String step;
  final bool isComplete;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = WmsOrderStatusBadge.foregroundFor(step);

    return Tooltip(
      message: step,
      child: Container(
        width: isCurrent ? 10 : 8,
        height: isCurrent ? 10 : 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isComplete
              ? color
              : isCurrent
                  ? color.withValues(alpha: 0.15)
                  : context.wms.surfaceVariant,
          border: isCurrent ? Border.all(color: color, width: 2) : null,
        ),
      ),
    );
  }
}

class OrdersEnterpriseCard extends StatelessWidget {
  const OrdersEnterpriseCard({
    super.key,
    required this.order,
    required this.warehouse,
    required this.onTap,
    this.onUpdateStatus,
    this.onTrack,
  });

  final WarehouseOrder order;
  final String warehouse;
  final VoidCallback onTap;
  final VoidCallback? onUpdateStatus;
  final VoidCallback? onTrack;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final accent = OrdersUi.statusAccent(order.status);

    return AppCard(
      onTap: onTap,
      elevated: true,
      accentColor: accent,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.orderNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        WmsOrderStatusBadge(status: order.status, compact: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.warehouse_outlined,
                            size: 10, color: wms.textTertiary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            warehouse,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.supportingDense(context).copyWith(
                                  color: wms.textTertiary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    WmsFormatters.currency(order.grandTotal),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1,
                        ),
                  ),
                  Text(
                    '${order.itemCount} items',
                    style: WmsDesignTokens.supportingDense(context).copyWith(
                          color: wms.textTertiary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          OrdersCompactLifecycleStepper(status: order.status),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.createdAt == null
                      ? '—'
                      : 'Ordered ${WmsFormatters.relativeTime(order.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: wms.textTertiary,
                      ),
                ),
              ),
              if (order.expectedDeliveryDate != null)
                Text(
                  'ETA ${WmsFormatters.notificationTimestamp(order.expectedDeliveryDate)}',
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: wms.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              WmsCardAction(
                icon: Icons.visibility_outlined,
                label: 'Details',
                onTap: onTap,
              ),
              WmsCardAction(
                icon: Icons.edit_outlined,
                label: 'Status',
                onTap: onUpdateStatus ?? onTap,
              ),
              WmsCardAction(
                icon: Icons.route_outlined,
                label: 'Track',
                onTap: onTrack ?? onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrdersCreateFormCard extends StatelessWidget {
  const OrdersCreateFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      title: 'New order',
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

class OrdersNotificationCard extends StatelessWidget {
  const OrdersNotificationCard({super.key, required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final accent = notification.read ? wms.textSecondary : AppColors.primary;

    return AppCard(
      elevated: true,
      accentColor: notification.read ? null : AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            notification.read
                ? Icons.notifications_none_outlined
                : Icons.notifications_active_outlined,
            size: WmsIconSizes.listLeading,
            color: accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.body(context).copyWith(
                        color: wms.textSecondary,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  WmsFormatters.notificationTimestamp(notification.createdAt),
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                        color: wms.textTertiary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrdersAnalyticsPanel extends StatelessWidget {
  const OrdersAnalyticsPanel({super.key, required this.data});

  final OrdersViewState data;

  @override
  Widget build(BuildContext context) {
    if (data.orders.isEmpty) {
      return const SizedBox.shrink();
    }

    final weekly = OrdersMetrics.weeklyPerformance(data);
    final weekDelta = weekly.lastWeek == 0
        ? weekly.thisWeek
        : weekly.thisWeek - weekly.lastWeek;
    final weekTrend = weekDelta >= 0 ? Icons.trending_up : Icons.trending_down;
    final weekColor = weekDelta >= 0 ? AppColors.success : AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrdersPipelineBar(data: data),
        const SizedBox(height: OrdersUi.sectionGap),
        WmsDashboardSection(
          title: 'Executive KPIs',
          child: WmsKpiGrid(
            children: [
              WmsKpiTile(
                label: 'Fulfillment Rate',
                value: '${OrdersMetrics.fulfillmentRate(data)}%',
                icon: Icons.verified_outlined,
                color: AppColors.success,
              ),
              WmsKpiTile(
                label: 'Orders Today',
                value: '${OrdersMetrics.ordersToday(data)}',
                icon: Icons.today_outlined,
                color: AppColors.primary,
              ),
              WmsKpiTile(
                label: 'This Week',
                value: '${OrdersMetrics.ordersThisWeek(data)}',
                icon: Icons.date_range_outlined,
                color: AppColors.info,
              ),
              WmsKpiTile(
                label: 'Avg Processing',
                value: OrdersMetrics.averageProcessingTime(data),
                icon: Icons.timer_outlined,
                color: AppColors.accent,
                compactValue: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: OrdersUi.sectionGap),
        OrdersChartCard(
          title: 'Daily Orders Trend',
          height: 160,
          child: OrdersSimpleLineChart(
            series: OrdersMetrics.dailyTrend(data),
          ),
        ),
        const SizedBox(height: OrdersUi.sectionGap),
        WmsDashboardSection(
          title: 'Weekly Performance',
          child: AppCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _AnalyticsStat(
                    label: 'This week',
                    value: '${weekly.thisWeek}',
                    color: AppColors.primary,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: _AnalyticsStat(
                    label: 'Last week',
                    value: '${weekly.lastWeek}',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      Icon(weekTrend, size: WmsIconSizes.kpi, color: weekColor),
                      Text(
                        '${weekDelta >= 0 ? '+' : ''}$weekDelta',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: weekColor,
                            ),
                      ),
                      Text(
                        'Change',
                        style: WmsDesignTokens.supportingDense(context).copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: OrdersUi.sectionGap),
        OrdersChartCard(
          title: 'Warehouse Distribution',
          height: 180,
          child: OrdersSimpleBarChart(
            series: OrdersMetrics.warehouseDistribution(data),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsStat extends StatelessWidget {
  const _AnalyticsStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
        ),
        Text(
          label,
          style: WmsDesignTokens.kpiLabel(context),
        ),
      ],
    );
  }
}

class OrdersChartCard extends StatelessWidget {
  const OrdersChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height = 200,
  });

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return WmsDashboardSection(
      title: title,
      child: AppCard(
        elevated: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(height: height, child: child),
      ),
    );
  }
}

class OrdersSimpleBarChart extends StatelessWidget {
  const OrdersSimpleBarChart({super.key, required this.series});

  final List<MapEntry<String, double>> series;

  @override
  Widget build(BuildContext context) {
    final data = series.take(6).toList();
    final maxY = data.fold<double>(0, (m, e) => math.max(m, e.value));
    if (data.isEmpty) return const SizedBox.shrink();

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 10 : maxY * 1.2,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 22),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[i].key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.chartAxis(context),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].value,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.primary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class OrdersSimpleLineChart extends StatelessWidget {
  const OrdersSimpleLineChart({super.key, required this.series});

  final List<MapEntry<String, double>> series;

  @override
  Widget build(BuildContext context) {
    final data = series;
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = data.fold<double>(0, (m, e) => math.max(m, e.value));

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 10 : maxY * 1.2,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 22),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Text(
                  data[i].key,
                  style: WmsDesignTokens.chartAxis(context),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i].value),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep pie chart for potential reuse
class OrdersSimplePieChart extends StatelessWidget {
  const OrdersSimplePieChart({super.key, required this.series});

  final List<MapEntry<String, double>> series;

  @override
  Widget build(BuildContext context) {
    final data = series.where((e) => e.value > 0).toList();
    if (data.isEmpty) return const SizedBox.shrink();
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 24,
        sections: [
          for (var i = 0; i < data.length; i++)
            PieChartSectionData(
              value: data[i].value,
              title: '${data[i].value.toInt()}',
              radius: 48,
              color: colors[i % colors.length],
              titleStyle: WmsDesignTokens.supportingDense(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile Orders page — web-parity structure optimized for phones (360–430dp).
// ---------------------------------------------------------------------------

/// Page header: title, subtitle, full-width New Order button.
class OrdersMobileHeader extends StatelessWidget {
  const OrdersMobileHeader({super.key, required this.onNewOrder});

  final VoidCallback onNewOrder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Order Operations',
            maxLines: 2,
            softWrap: true,
            style: WmsDesignTokens.pageTitle(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Warehouse fulfillment pipeline',
            style: WmsDesignTokens.pageSubtitle(context),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onNewOrder,
              icon: const Icon(Icons.add, size: WmsIconSizes.actionButton),
              label: const Text('New Order'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                textStyle: WmsDesignTokens.buttonLabel(context).copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersMobileKpiDef {
  const _OrdersMobileKpiDef(this.label, this.value, this.status, this.color);
  final String label;
  final int value;
  final String? status;
  final Color color;
}

/// Two-column KPI grid — Pending, Processing, Packed, Shipped, Delivered.
class OrdersMobileKpiGrid extends StatelessWidget {
  const OrdersMobileKpiGrid({
    super.key,
    required this.data,
    this.onStatusTap,
  });

  final OrdersViewState data;
  final ValueChanged<String?>? onStatusTap;

  @override
  Widget build(BuildContext context) {
    final breakdown = OrdersMetrics.pipelineBreakdown(data);
    final items = [
      _OrdersMobileKpiDef(
        'Pending',
        breakdown.pending,
        WmsOrderStatuses.pending,
        WmsOrderStatusBadge.foregroundFor(WmsOrderStatuses.pending),
      ),
      _OrdersMobileKpiDef(
        'Processing',
        breakdown.processing,
        WmsOrderStatuses.processing,
        WmsOrderStatusBadge.foregroundFor(WmsOrderStatuses.processing),
      ),
      _OrdersMobileKpiDef(
        'Packed',
        breakdown.packed,
        WmsOrderStatuses.packed,
        WmsOrderStatusBadge.foregroundFor(WmsOrderStatuses.packed),
      ),
      _OrdersMobileKpiDef(
        'Shipped',
        breakdown.shipped,
        WmsOrderStatuses.shipped,
        WmsOrderStatusBadge.foregroundFor(WmsOrderStatuses.shipped),
      ),
      _OrdersMobileKpiDef(
        'Delivered',
        breakdown.delivered,
        WmsOrderStatuses.delivered,
        WmsOrderStatusBadge.foregroundFor(WmsOrderStatuses.delivered),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: MobileUi.phoneKpiGridDelegate(),
        children: [
          for (final item in items)
            AppCard(
              elevated: true,
              onTap: onStatusTap != null
                  ? () => onStatusTap!(item.status)
                  : null,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    WmsOrderStatusBadge.iconFor(item.label),
                    size: WmsIconSizes.kpi,
                    color: item.color,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${item.value}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.cardNumber(context).copyWith(
                      color: item.color,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.kpiLabel(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-width search with horizontal status filter chips.
class OrdersMobileSearchSection extends StatelessWidget {
  const OrdersMobileSearchSection({
    super.key,
    required this.data,
    required this.searchController,
    required this.onSearch,
    required this.onStatusFilter,
  });

  final OrdersViewState data;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatusFilter;

  static const _mobileStatuses = [
    WmsOrderStatuses.pending,
    WmsOrderStatuses.processing,
    WmsOrderStatuses.packed,
    WmsOrderStatuses.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final selected = data.statusFilter;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearch,
            style: WmsDesignTokens.inputText(context),
            decoration: InputDecoration(
              hintText: 'Search orders…',
              hintStyle: WmsDesignTokens.body(context).copyWith(
                color: colors.textTertiary,
              ),
              prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _OrdersMobileFilterChip(
                  label: 'All',
                  selected: selected == null || selected.isEmpty,
                  color: AppColors.primary,
                  onTap: () => onStatusFilter(null),
                ),
                for (final status in _mobileStatuses) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _OrdersMobileFilterChip(
                    label: status,
                    selected: selected == status,
                    color: WmsOrderStatusBadge.foregroundFor(status),
                    onTap: () => onStatusFilter(
                      selected == status ? null : status,
                    ),
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

class _OrdersMobileFilterChip extends StatelessWidget {
  const _OrdersMobileFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return FilterChip(
      label: Text(
        label,
        style: WmsDesignTokens.body(context).copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? color : colors.textSecondary,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: selected ? color : colors.border),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

/// Mobile order card — vertical layout with View Details action.
class OrdersMobileCard extends StatelessWidget {
  const OrdersMobileCard({
    super.key,
    required this.order,
    required this.warehouse,
    required this.onTap,
  });

  final WarehouseOrder order;
  final String warehouse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final created = order.createdAt;
    final dateLabel = created != null ? _shortMonthDay(created) : '—';

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.orderNumber,
            style: WmsDesignTokens.cardTitle(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            order.customerName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.body(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            warehouse,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WmsDesignTokens.pageSubtitle(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          WmsOrderStatusBadge(status: order.status),
          const SizedBox(height: AppSpacing.md),
          Text(
            WmsFormatters.currency(order.grandTotal),
            style: WmsDesignTokens.cardNumber(context).copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            dateLabel,
            style: WmsDesignTokens.pageSubtitle(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(Icons.visibility_outlined, size: WmsIconSizes.actionButton),
              label: const Text('View Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortMonthDay(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

/// Bottom sheet for creating a new order (preserves existing create flow).
void showCreateOrderSheet(
  BuildContext context, {
  required OrdersViewState data,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (ctx) {
      return _OrdersCreateOrderSheet(data: data);
    },
  );
}

class _OrdersCreateOrderSheet extends StatefulWidget {
  const _OrdersCreateOrderSheet({required this.data});

  final OrdersViewState data;

  @override
  State<_OrdersCreateOrderSheet> createState() => _OrdersCreateOrderSheetState();
}

class _OrdersCreateOrderSheetState extends State<_OrdersCreateOrderSheet> {
  final _customerCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Product? _product;
  String? _warehouse;

  @override
  void dispose() {
    _customerCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Order', style: WmsDesignTokens.sectionTitle(context)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _customerCtrl,
              decoration: const InputDecoration(labelText: 'Customer'),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<Product>(
              initialValue: _product,
              decoration: const InputDecoration(labelText: 'Product'),
              items: [
                for (final product in widget.data.products)
                  DropdownMenuItem(
                    value: product,
                    child: Text('${product.name} · ${product.sku}'),
                  ),
              ],
              onChanged: (value) => setState(() => _product = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _warehouse,
              decoration: const InputDecoration(labelText: 'Warehouse'),
              items: [
                for (final warehouse in widget.data.warehouses)
                  DropdownMenuItem(value: warehouse, child: Text(warehouse)),
              ],
              onChanged: (value) => setState(() => _warehouse = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Create Order UI is ready. Current backend integration exposes order list/detail/status update only.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Create Order'),
            ),
          ],
        ),
      ),
    );
  }
}
