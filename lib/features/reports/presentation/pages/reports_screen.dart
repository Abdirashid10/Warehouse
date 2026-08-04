import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/core/utils/wms_route_context.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_analytics_cubit.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_kpi_strip.dart';
import 'package:logisticsmobile/widgets/wms/wms_pushed_scaffold.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with StaffScopeInitMixin {
  ReportsAnalyticsCubit? _cubit;
  AnalyticsDatePreset _preset = AnalyticsDatePreset.month;
  DateTimeRange? _customRange;

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _cubit = ReportsAnalyticsCubit(repositories)..load();
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange,
    );
    if (range == null || !mounted) return;
    setState(() {
      _customRange = range;
      _preset = AnalyticsDatePreset.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    final colors = WmsUiColors.of(context);
    if (cubit == null) {
      return const WmsPushedScaffold(
        title: 'Reports & Analytics',
        body: StaffScopeLoadingBody(),
      );
    }

    return WmsPushedScaffold(
      title: 'Reports & Analytics',
      body: BlocProvider.value(
        value: cubit,
        child: BlocBuilder<ReportsAnalyticsCubit, ResourceState<ReportsAnalyticsBundle>>(
          builder: (context, state) {
            if (state.isLoading && state.data == null) {
              return const _ReportsLoadingView();
            }
            if (state.isFailure && state.data == null) {
              return WmsErrorState(
                message: state.message ?? 'Failed to load analytics',
                onRetry: cubit.load,
              );
            }
            final bundle = state.data;
            if (bundle == null) {
              return WmsErrorState(
                message: state.message ?? 'No analytics data',
                onRetry: cubit.load,
              );
            }

            final computed = AnalyticsComputer.compute(
              bundle: bundle,
              preset: _preset,
              customRange: _customRange,
            );

            if (!computed.hasAnyData) {
              return WmsEmptyState(
                title: 'No analytics available',
                message:
                    'Connect to your warehouse backend to populate reporting datasets.',
                icon: Icons.analytics_outlined,
              );
            }

            return DefaultTabController(
              length: 7,
              child: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _ReportsExecutiveHeader(
                        rangeLabel: computed.rangeLabel,
                        isAdmin: context.isAdminWorkspace,
                        isSupervisor: context.isSupervisorWorkspace,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.md,
                          AppSpacing.screenPadding,
                          0,
                        ),
                        child: _DateFilterBar(
                          preset: _preset,
                          customRange: _customRange,
                          onPreset: (value) async {
                            if (value == AnalyticsDatePreset.custom) {
                              await _pickCustomRange();
                            } else {
                              setState(() => _preset = value);
                            }
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        child: _ExecutiveKpiDashboard(computed: computed),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _ReportsTabDelegate(
                        child: Container(
                          color: colors.background,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                            vertical: AppSpacing.sm,
                          ),
                          child: const TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: [
                              Tab(text: 'Inventory'),
                              Tab(text: 'Orders'),
                              Tab(text: 'Warehouse'),
                              Tab(text: 'Stock'),
                              Tab(text: 'Tasks'),
                              Tab(text: 'Users'),
                              Tab(text: 'Export'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: TabBarView(
                          children: [
                            _InventoryAnalyticsTab(computed: computed),
                            _OrdersAnalyticsTab(computed: computed),
                            _WarehouseAnalyticsTab(computed: computed),
                            _MovementAnalyticsTab(computed: computed),
                            _TaskAnalyticsTab(computed: computed),
                            _UserAnalyticsTab(computed: computed),
                            const _ExportCenterTab(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportsExecutiveHeader extends StatelessWidget {
  const _ReportsExecutiveHeader({
    required this.rangeLabel,
    required this.isAdmin,
    required this.isSupervisor,
  });

  final String rangeLabel;
  final bool isAdmin;
  final bool isSupervisor;

  @override
  Widget build(BuildContext context) {
    final subtitle = isAdmin
        ? 'Organization-wide business intelligence and operational KPIs'
        : isSupervisor
            ? 'Warehouse performance analytics and team oversight metrics'
            : 'Operational reporting for your assigned warehouse';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusXl),
          bottomRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.insights, color: Colors.white, size: WmsIconSizes.kpi),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics Center',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, color: Colors.white, size: WmsIconSizes.actionButton),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Reporting period: $rangeLabel',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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

class _DateFilterBar extends StatelessWidget {
  const _DateFilterBar({
    required this.preset,
    required this.customRange,
    required this.onPreset,
  });

  final AnalyticsDatePreset preset;
  final DateTimeRange? customRange;
  final ValueChanged<AnalyticsDatePreset> onPreset;

  @override
  Widget build(BuildContext context) {
    final items = <(AnalyticsDatePreset, String)>[
      (AnalyticsDatePreset.today, 'Today'),
      (AnalyticsDatePreset.week, 'This Week'),
      (AnalyticsDatePreset.month, 'This Month'),
      (AnalyticsDatePreset.year, 'This Year'),
      (
        AnalyticsDatePreset.custom,
        customRange == null ? 'Custom Range' : 'Custom',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date filters',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in items) ...[
                FilterChip(
                  label: Text(item.$2),
                  selected: preset == item.$1,
                  onSelected: (_) => onPreset(item.$1),
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExecutiveKpiDashboard extends StatelessWidget {
  const _ExecutiveKpiDashboard({required this.computed});

  final AnalyticsComputed computed;

  @override
  Widget build(BuildContext context) {
    final bundle = computed.bundle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Executive KPI dashboard',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Snapshot metrics plus period-filtered orders, tasks, and movements',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WmsUiColors.of(context).textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        WmsKpiStrip(
          items: [
            WmsKpiItem(
              label: 'Total Products',
              value: '${bundle.products.length}',
              icon: Icons.category_outlined,
              color: AppColors.primary,
              background: AppColors.primaryLight,
            ),
            WmsKpiItem(
              label: 'Total Inventory',
              value: WmsFormatters.quantity(bundle.inventoryTracking.summary.totalUnits),
              icon: Icons.inventory_2_outlined,
              color: AppColors.info,
              background: AppColors.infoLight,
            ),
            WmsKpiItem(
              label: 'Total Warehouses',
              value: '${bundle.warehouses.length}',
              icon: Icons.warehouse_outlined,
              color: AppColors.accent,
              background: AppColors.accentLight,
            ),
            WmsKpiItem(
              label: 'Orders (${computed.rangeLabel})',
              value: '${computed.filteredOrders.length}',
              icon: Icons.shopping_cart_outlined,
              color: AppColors.success,
              background: AppColors.successLight,
            ),
            WmsKpiItem(
              label: 'Total Users',
              value: '${bundle.users.where((u) => !u.archived).length}',
              icon: Icons.people_outline,
              color: const Color(0xFF1D4ED8),
              background: const Color(0xFFDBEAFE),
            ),
            WmsKpiItem(
              label: 'Tasks (${computed.rangeLabel})',
              value: '${computed.filteredTasks.length}',
              icon: Icons.assignment_outlined,
              color: AppColors.warning,
              background: AppColors.warningLight,
            ),
            WmsKpiItem(
              label: 'Stock Value',
              value: WmsFormatters.currency(bundle.reports.valuation.costValue),
              icon: Icons.payments_outlined,
              color: AppColors.success,
              background: AppColors.successLight,
            ),
            WmsKpiItem(
              label: 'Low Stock',
              value: '${bundle.inventoryTracking.summary.lowStock}',
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              background: AppColors.warningLight,
            ),
            WmsKpiItem(
              label: 'Expiring Soon',
              value: '${bundle.expiringSoonCount}',
              icon: Icons.event_busy_outlined,
              color: AppColors.error,
              background: AppColors.errorLight,
            ),
            WmsKpiItem(
              label: 'Movements (${computed.rangeLabel})',
              value: '${computed.filteredMovements.length}',
              icon: Icons.swap_horiz_rounded,
              color: AppColors.info,
              background: AppColors.infoLight,
            ),
            WmsKpiItem(
              label: 'Active Users',
              value: '${bundle.activeUsersCount}',
              icon: Icons.verified_user_outlined,
              color: AppColors.primary,
              background: AppColors.primaryLight,
            ),
          ],
        ),
      ],
    );
  }
}

class _InventoryAnalyticsTab extends StatelessWidget {
  const _InventoryAnalyticsTab({required this.computed});

  final AnalyticsComputed computed;

  @override
  Widget build(BuildContext context) {
    final items = computed.bundle.inventoryTracking.items;
    if (items.isEmpty) {
      return const _TabEmptyState(
        title: 'No inventory analytics',
        message: 'Inventory data will appear when stock lines are available.',
      );
    }

    final byWarehouse = <String, double>{};
    final statusDist = <String, double>{};
    for (final i in items) {
      byWarehouse[i.warehouseName] =
          (byWarehouse[i.warehouseName] ?? 0) + i.quantity.toDouble();
      statusDist[i.stockStatus] = (statusDist[i.stockStatus] ?? 0) + 1;
    }

    final byCategory = <String, double>{};
    for (final p in computed.bundle.products) {
      final key = p.category?.isNotEmpty == true ? p.category! : 'Uncategorized';
      byCategory[key] = (byCategory[key] ?? 0) + 1;
    }

    final summary = computed.bundle.inventoryTracking.summary;

    return _AnalyticsScrollTab(
      children: [
        _SectionIntro(
          title: 'Inventory analytics',
          subtitle: 'Stock by warehouse, category mix, distribution, and low-stock exposure',
        ),
        _ChartCard(
          title: 'Stock by Warehouse',
          child: _BarChartWidget(series: byWarehouse.entries.toList()),
        ),
        _ChartCard(
          title: 'Stock by Category',
          child: _PieChartWidget(series: byCategory.entries.toList()),
        ),
        _ChartCard(
          title: 'Inventory Distribution',
          child: _PieChartWidget(series: statusDist.entries.toList()),
        ),
        _ChartCard(
          title: 'Low Stock Analysis',
          child: _BarChartWidget(
            series: [
              MapEntry('Low', summary.lowStock.toDouble()),
              MapEntry('Out', summary.outOfStock.toDouble()),
              MapEntry('In Stock', summary.inStock.toDouble()),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdersAnalyticsTab extends StatelessWidget {
  const _OrdersAnalyticsTab({required this.computed});

  final AnalyticsComputed computed;

  @override
  Widget build(BuildContext context) {
    final orders = computed.filteredOrders;
    if (orders.isEmpty) {
      return _TabEmptyState(
        title: 'No orders in range',
        message: 'Adjust the date filter to ${computed.rangeLabel} with order activity.',
      );
    }

    final byStatus = <String, double>{};
    final byMonth = <String, double>{};
    final byDay = <String, double>{};
    for (final o in orders) {
      byStatus[o.status] = (byStatus[o.status] ?? 0) + 1;
      final dt = o.createdAt;
      if (dt != null) {
        byMonth[AnalyticsDateFormatters.monthKey(dt)] =
            (byMonth[AnalyticsDateFormatters.monthKey(dt)] ?? 0) + 1;
        byDay[AnalyticsDateFormatters.dayKey(dt)] =
            (byDay[AnalyticsDateFormatters.dayKey(dt)] ?? 0) + 1;
      }
    }
    final delivered = byStatus[WmsOrderStatuses.delivered] ?? 0;
    final pending = orders.length - delivered;

    return _AnalyticsScrollTab(
      children: [
        const _SectionIntro(
          title: 'Orders analytics',
          subtitle: 'Status pipeline, monthly volume, daily throughput, fulfillment ratio',
        ),
        _ChartCard(
          title: 'Orders by Status',
          child: _PieChartWidget(series: byStatus.entries.toList()),
        ),
        _ChartCard(
          title: 'Monthly Orders',
          child: _LineChartWidget(
            series: byMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
          ),
        ),
        _ChartCard(
          title: 'Daily Orders',
          child: _LineChartWidget(
            series: byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
          ),
        ),
        _ChartCard(
          title: 'Delivered vs Pending',
          child: _PieChartWidget(
            series: [
              MapEntry('Delivered', delivered),
              MapEntry('Pending', pending.toDouble()),
            ],
          ),
        ),
      ],
    );
  }
}

class _WarehouseAnalyticsTab extends StatelessWidget {
  const _WarehouseAnalyticsTab({required this.computed});

  final AnalyticsComputed computed;

  @override
  Widget build(BuildContext context) {
    final warehouses = computed.bundle.warehouses;
    if (warehouses.isEmpty) {
      return const _TabEmptyState(
        title: 'No warehouse analytics',
        message: 'Warehouse metrics appear when warehouse records are loaded.',
      );
    }

    final inventoryByWarehouse = <String, double>{};
    for (final item in computed.bundle.inventoryTracking.items) {
      inventoryByWarehouse[item.warehouseName] =
          (inventoryByWarehouse[item.warehouseName] ?? 0) + item.quantity.toDouble();
    }

    final capacityUsage = <String, double>{};
    for (final w in warehouses) {
      final used = inventoryByWarehouse[w.name] ?? 0;
      final pct = w.capacity > 0 ? (used / w.capacity * 100).clamp(0, 100) : 0;
      capacityUsage[w.name] = pct.toDouble();
    }

    final staffDist = {for (final w in warehouses) w.name: w.staffCount.toDouble()};
    final activity = <String, double>{for (final w in warehouses) w.name: 0};
    for (final m in computed.filteredMovements) {
      final source = m.fromLocation;
      final target = m.toLocation;
      if (source != null && activity.containsKey(source)) {
        activity[source] = activity[source]! + 1;
      }
      if (target != null && activity.containsKey(target)) {
        activity[target] = activity[target]! + 1;
      }
    }

    return _AnalyticsScrollTab(
      children: [
        const _SectionIntro(
          title: 'Warehouse analytics',
          subtitle: 'Capacity usage, inventory load, staff distribution, and activity',
        ),
        _ChartCard(
          title: 'Capacity Usage (%)',
          child: _BarChartWidget(series: capacityUsage.entries.toList()),
        ),
        _ChartCard(
          title: 'Inventory per Warehouse',
          child: _BarChartWidget(series: inventoryByWarehouse.entries.toList()),
        ),
        _ChartCard(
          title: 'Staff Distribution',
          child: _PieChartWidget(series: staffDist.entries.toList()),
        ),
        _ChartCard(
          title: 'Warehouse Activity',
          child: _BarChartWidget(series: activity.entries.toList()),
        ),
      ],
    );
  }
}

class _MovementAnalyticsTab extends StatelessWidget {
  const _MovementAnalyticsTab({required this.computed});

  final AnalyticsComputed computed;

  @override
  Widget build(BuildContext context) {
    final movements = computed.filteredMovements;
    if (movements.isEmpty) {
      return _TabEmptyState(
        title: 'No movements in range',
        message: 'Stock movement charts use the selected reporting period.',
      );
    }

    final byType = <String, double>{};
    final daily = <String, double>{};
    final monthly = <String, double>{};
    final transferDaily = <String, double>{};
    for (final m in movements) {
      byType[m.type] = (byType[m.type] ?? 0) + 1;
      final dt = m.timestamp;
      if (dt != null) {
        daily[AnalyticsDateFormatters.dayKey(dt)] =
            (daily[AnalyticsDateFormatters.dayKey(dt)] ?? 0) + 1;
        monthly[AnalyticsDateFormatters.monthKey(dt)] =
            (monthly[AnalyticsDateFormatters.monthKey(dt)] ?? 0) + 1;
        if (m.type == WmsMovementTypes.transfer) {
          transferDaily[AnalyticsDateFormatters.dayKey(dt)] =
              (transferDaily[AnalyticsDateFormatters.dayKey(dt)] ?? 0) + 1;
        }
      }
    }

    return _AnalyticsScrollTab(
      children: [
        const _SectionIntro(
          title: 'Stock movement analytics',
          subtitle: 'Inbound vs outbound, transfers, daily volume, and monthly trends',
        ),
        _ChartCard(
          title: 'Inbound vs Outbound',
          child: _PieChartWidget(
            series: [
              MapEntry('Inbound', byType[WmsMovementTypes.inbound] ?? 0),
              MapEntry('Outbound', byType[WmsMovementTypes.outbound] ?? 0),
            ],
          ),
        ),
        _ChartCard(
          title: 'Transfer Activity',
          child: _LineChartWidget(
            series: transferDaily.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)),
          ),
        ),
        _ChartCard(
          title: 'Daily Movements',
          child: _BarChartWidget(
            series: daily.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
          ),
        ),
        _ChartCard(
          title: 'Monthly Trends',
          child: _LineChartWidget(
            series: monthly.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
          ),
        ),
      ],
    );
  }
}

class _TaskAnalyticsTab extends StatelessWidget {
  const _TaskAnalyticsTab({required this.computed});

  final AnalyticsComputed computed;

  @override
  Widget build(BuildContext context) {
    final tasks = computed.filteredTasks;
    if (tasks.isEmpty) {
      return _TabEmptyState(
        title: 'No tasks in range',
        message: 'Task analytics reflect tasks created or updated in the selected period.',
      );
    }

    final byStatus = <String, double>{};
    final staffPerformance = <String, double>{};
    var completed = 0.0;
    var overdue = 0.0;
    for (final t in tasks) {
      byStatus[t.status] = (byStatus[t.status] ?? 0) + 1;
      if (t.status == WmsTaskStatuses.completed) {
        completed += 1;
        final assignee =
            t.assignedToName?.isNotEmpty == true ? t.assignedToName! : 'Unassigned';
        staffPerformance[assignee] = (staffPerformance[assignee] ?? 0) + 1;
      }
      if (t.status == WmsTaskStatuses.overdue) overdue += 1;
    }

    return _AnalyticsScrollTab(
      children: [
        const _SectionIntro(
          title: 'Task analytics',
          subtitle: 'Status mix, completion vs overdue, and staff performance',
        ),
        _ChartCard(
          title: 'Tasks by Status',
          child: _PieChartWidget(series: byStatus.entries.toList()),
        ),
        _ChartCard(
          title: 'Completed vs Overdue',
          child: _BarChartWidget(
            series: [
              MapEntry('Completed', completed),
              MapEntry('Overdue', overdue),
            ],
          ),
        ),
        _ChartCard(
          title: 'Staff Performance',
          child: _BarChartWidget(series: staffPerformance.entries.toList()),
        ),
      ],
    );
  }
}

class _UserAnalyticsTab extends StatelessWidget {
  const _UserAnalyticsTab({required this.computed});

  final AnalyticsComputed computed;

  @override
  Widget build(BuildContext context) {
    final users = computed.bundle.users.where((u) => !u.archived).toList();
    if (users.isEmpty) {
      return const _TabEmptyState(
        title: 'No user analytics',
        message: 'User segmentation charts appear when workforce data is available.',
      );
    }

    final byRole = <String, double>{};
    final byStatus = <String, double>{};
    for (final u in users) {
      byRole[u.role] = (byRole[u.role] ?? 0) + 1;
      byStatus[u.status] = (byStatus[u.status] ?? 0) + 1;
    }

    final assignments = {
      for (final w in computed.bundle.warehouses) w.name: w.staffCount.toDouble(),
    };

    return _AnalyticsScrollTab(
      children: [
        const _SectionIntro(
          title: 'User analytics',
          subtitle: 'Role segmentation, activation status, and warehouse assignments',
        ),
        _ChartCard(
          title: 'Users by Role',
          child: _PieChartWidget(series: byRole.entries.toList()),
        ),
        _ChartCard(
          title: 'Active Users',
          child: _BarChartWidget(series: byStatus.entries.toList()),
        ),
        _ChartCard(
          title: 'Warehouse Assignments',
          child: _BarChartWidget(series: assignments.entries.toList()),
        ),
      ],
    );
  }
}

class _ExportCenterTab extends StatelessWidget {
  const _ExportCenterTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xxl,
      ),
      children: [
        const _SectionIntro(
          title: 'Export center',
          subtitle: 'Prepare executive reports for sharing (UI ready; backend export pending)',
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available formats',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 520 ? 3 : (width >= 340 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 2.4,
                    children: const [
                      _ExportTile(
                        label: 'PDF Export',
                        icon: Icons.picture_as_pdf_outlined,
                        description: 'Executive summary pack',
                      ),
                      _ExportTile(
                        label: 'Excel Export',
                        icon: Icons.table_view_outlined,
                        description: 'Spreadsheet workbook',
                      ),
                      _ExportTile(
                        label: 'CSV Export',
                        icon: Icons.description_outlined,
                        description: 'Raw data tables',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.label,
    required this.icon,
    required this.description,
  });

  final String label;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$label is ready. Connect backend export endpoint to generate files.',
            ),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(AppSpacing.md),
        alignment: Alignment.centerLeft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            description,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: WmsUiColors.of(context).textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WmsUiColors.of(context).textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsScrollTab extends StatelessWidget {
  const _AnalyticsScrollTab({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: WmsEmptyState(
        title: title,
        message: message,
        icon: Icons.stacked_line_chart_outlined,
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  const _BarChartWidget({required this.series});

  final List<MapEntry<String, double>> series;

  @override
  Widget build(BuildContext context) {
    final data = series.take(8).toList();
    if (data.isEmpty) return const _ChartEmptyState();
    final maxY = data.fold<double>(0, (max, e) => math.max(max, e.value));

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 10 : maxY * 1.2,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[index].key,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
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
                  borderRadius: BorderRadius.circular(4),
                  width: 18,
                  gradient: AppColors.brandGradient,
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }
}

class _PieChartWidget extends StatelessWidget {
  const _PieChartWidget({required this.series});

  final List<MapEntry<String, double>> series;

  @override
  Widget build(BuildContext context) {
    final data = series.where((e) => e.value > 0).toList();
    if (data.isEmpty) return const _ChartEmptyState();
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: [
                for (var i = 0; i < data.length; i++)
                  PieChartSectionData(
                    value: data[i].value,
                    radius: 56,
                    title: '${data[i].value.toInt()}',
                    color: colors[i % colors.length],
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (var i = 0; i < data.length; i++)
              _LegendDot(
                color: colors[i % colors.length],
                label: '${data[i].key}: ${data[i].value.toInt()}',
              ),
          ],
        ),
      ],
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({required this.series});

  final List<MapEntry<String, double>> series;

  @override
  Widget build(BuildContext context) {
    final data = series.take(12).toList();
    if (data.isEmpty) return const _ChartEmptyState();
    final maxY = data.fold<double>(0, (max, e) => math.max(max, e.value));

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 10 : maxY * 1.2,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(data[i].key, style: const TextStyle(fontSize: 12)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: const FlDotData(show: true),
            spots: [
              for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].value),
            ],
          ),
        ],
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: WmsEmptyState(
        title: 'No chart data',
        message: 'Adjust filters or date range to visualize analytics.',
        icon: Icons.stacked_line_chart_outlined,
      ),
    );
  }
}

class _ReportsLoadingView extends StatelessWidget {
  const _ReportsLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        WmsSkeletonBox(height: 140, radius: AppSpacing.radiusXl),
        SizedBox(height: AppSpacing.md),
        WmsSkeletonBox(height: 44, radius: AppSpacing.radiusMd),
        SizedBox(height: AppSpacing.md),
        WmsKpiSkeleton(),
        SizedBox(height: AppSpacing.sectionGap),
        WmsSkeletonBox(height: 48, radius: AppSpacing.radiusMd),
        SizedBox(height: AppSpacing.md),
        WmsSkeletonBox(height: 240, radius: AppSpacing.radiusLg),
        SizedBox(height: AppSpacing.md),
        WmsSkeletonBox(height: 240, radius: AppSpacing.radiusLg),
      ],
    );
  }
}

class _ReportsTabDelegate extends SliverPersistentHeaderDelegate {
  _ReportsTabDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 62;

  @override
  double get maxExtent => 62;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _ReportsTabDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
