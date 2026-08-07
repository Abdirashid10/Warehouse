import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/core/utils/wms_route_context.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_analytics_cubit.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_trends.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_atoms.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_theme.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_tab_views.dart';
import 'package:logisticsmobile/widgets/wms/wms_pushed_scaffold.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Reports & Analytics — the executive analytics centre.
///
/// Composition: a gradient hero with the reporting-period control, a bento KPI
/// grid, then a pinned pill tab bar over seven analytics surfaces.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with StaffScopeInitMixin, TickerProviderStateMixin {
  static const _tabs = [
    ReportsTabSpec(label: 'Inventory', icon: Icons.inventory_2_rounded),
    ReportsTabSpec(label: 'Orders', icon: Icons.shopping_cart_rounded),
    ReportsTabSpec(label: 'Warehouse', icon: Icons.warehouse_rounded),
    ReportsTabSpec(label: 'Stock', icon: Icons.swap_horiz_rounded),
    ReportsTabSpec(label: 'Tasks', icon: Icons.task_alt_rounded),
    ReportsTabSpec(label: 'Users', icon: Icons.groups_rounded),
    ReportsTabSpec(label: 'Export', icon: Icons.ios_share_rounded),
  ];

  static const _periodOptions = [
    ReportsPeriodOption(
      value: AnalyticsDatePreset.today,
      label: 'Today',
      icon: Icons.today_rounded,
    ),
    ReportsPeriodOption(
      value: AnalyticsDatePreset.week,
      label: 'This Week',
      icon: Icons.view_week_rounded,
    ),
    ReportsPeriodOption(
      value: AnalyticsDatePreset.month,
      label: 'This Month',
      icon: Icons.calendar_view_month_rounded,
    ),
    ReportsPeriodOption(
      value: AnalyticsDatePreset.year,
      label: 'This Year',
      icon: Icons.calendar_month_rounded,
    ),
    ReportsPeriodOption(
      value: AnalyticsDatePreset.custom,
      label: 'Custom',
      icon: Icons.date_range_rounded,
    ),
  ];

  ReportsAnalyticsCubit? _cubit;
  late final TabController _tabController =
      TabController(length: _tabs.length, vsync: this);

  AnalyticsDatePreset _preset = AnalyticsDatePreset.month;
  DateTimeRange? _customRange;

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _cubit = ReportsAnalyticsCubit(repositories)..load();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _onPresetSelected(AnalyticsDatePreset preset) async {
    if (preset == AnalyticsDatePreset.custom) {
      await _pickCustomRange();
      return;
    }
    setState(() => _preset = preset);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const WmsPushedScaffold(
        title: 'Reports & Analytics',
        body: StaffScopeLoadingBody(),
      );
    }

    final palette = ReportsPalette.of(context);

    return WmsPushedScaffold(
      title: 'Reports & Analytics',
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.pageGradient),
        child: BlocProvider.value(
          value: cubit,
          child: BlocBuilder<ReportsAnalyticsCubit,
              ResourceState<ReportsAnalyticsBundle>>(
            builder: (context, state) {
              if (state.isLoading && state.data == null) {
                return const _ReportsLoadingView();
              }

              final bundle = state.data;
              if (bundle == null) {
                return WmsErrorState(
                  message: state.message ?? 'Failed to load analytics',
                  onRetry: cubit.load,
                );
              }

              final computed = AnalyticsComputer.compute(
                bundle: bundle,
                preset: _preset,
                customRange: _customRange,
              );

              if (!computed.hasAnyData) {
                return ReportsEmptyState(
                  title: 'No analytics available',
                  message:
                      'Connect to your warehouse backend to populate reporting '
                      'datasets for this workspace.',
                  actions: [
                    ReportsEmptyAction(
                      label: 'Retry',
                      icon: Icons.refresh_rounded,
                      onPressed: cubit.load,
                      primary: true,
                    ),
                  ],
                );
              }

              return _ReportsBody(
                computed: computed,
                tabController: _tabController,
                tabs: _tabs,
                periodOptions: _periodOptions,
                preset: _preset,
                onPreset: _onPresetSelected,
                onWidenPeriod: () =>
                    setState(() => _preset = AnalyticsDatePreset.year),
                onRefresh: cubit.refresh,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({
    required this.computed,
    required this.tabController,
    required this.tabs,
    required this.periodOptions,
    required this.preset,
    required this.onPreset,
    required this.onWidenPeriod,
    required this.onRefresh,
  });

  final AnalyticsComputed computed;
  final TabController tabController;
  final List<ReportsTabSpec> tabs;
  final List<ReportsPeriodOption<AnalyticsDatePreset>> periodOptions;
  final AnalyticsDatePreset preset;
  final ValueChanged<AnalyticsDatePreset> onPreset;
  final VoidCallback onWidenPeriod;
  final Future<void> Function() onRefresh;

  String _subtitleFor(BuildContext context) {
    if (context.isAdminWorkspace) {
      return 'Organization-wide business intelligence and operational KPIs';
    }
    if (context.isSupervisorWorkspace) {
      return 'Warehouse performance analytics and team oversight metrics';
    }
    return 'Operational reporting for your assigned warehouse';
  }

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final bundle = computed.bundle;
    final actions = ReportsTabActions(
      onWidenPeriod: onWidenPeriod,
      onRefresh: onRefresh,
    );

    return RefreshIndicator(
      color: palette.brand,
      backgroundColor: palette.colors.surface,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ReportsHeroBanner(
              title: 'Analytics Center',
              subtitle: _subtitleFor(context),
              child: ReportsPeriodSelector<AnalyticsDatePreset>(
                options: periodOptions,
                selected: preset,
                onSelected: onPreset,
                rangeLabel: computed.rangeLabel,
              ),
            ),
          ),
          if (bundle.isSampleData)
            const SliverToBoxAdapter(
              child: _NoticePadding(
                child: ReportsNoticeChip(
                  icon: Icons.science_outlined,
                  headline: 'Showing illustrative sample data',
                  detail:
                      'The analytics service is unreachable, so these figures '
                      'are placeholders. They must not be used for ordering, '
                      'staffing or valuation decisions.',
                  status: ReportsStatus.warning,
                  initiallyExpanded: true,
                ),
              ),
            )
          else if (bundle.isPartial)
            SliverToBoxAdapter(
              child: _NoticePadding(
                child: ReportsNoticeChip(
                  icon: Icons.lock_outline_rounded,
                  headline:
                      '${bundle.unavailableSources.length} section(s) hidden '
                      'for your role',
                  detail:
                      'Unavailable to this account: '
                      '${bundle.unavailableSources.join(', ')}. Everything '
                      'else on this screen is live.',
                  status: ReportsStatus.info,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: ReportsSectionIntro(
                eyebrow: 'Executive summary',
                title: 'KPI Dashboard',
                subtitle:
                    'Live snapshots plus period metrics for ${computed.rangeLabel}',
                trailing: ReportsGlowBadge(
                  icon: Icons.dashboard_customize_rounded,
                  color: palette.brand,
                  size: 38,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            sliver: _KpiBentoGrid(computed: computed),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _PillTabBarDelegate(
              background: palette.colors.background,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                ),
                child: ReportsPillTabBar(
                  controller: tabController,
                  tabs: tabs,
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
                controller: tabController,
                children: [
                  ReportsInventoryTab(computed: computed, actions: actions),
                  ReportsOrdersTab(computed: computed, actions: actions),
                  ReportsWarehouseTab(computed: computed, actions: actions),
                  ReportsMovementsTab(computed: computed, actions: actions),
                  ReportsTasksTab(computed: computed, actions: actions),
                  ReportsUsersTab(computed: computed, actions: actions),
                  ReportsExportTab(rangeLabel: computed.rangeLabel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticePadding extends StatelessWidget {
  const _NoticePadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        0,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI bento grid
// ─────────────────────────────────────────────────────────────────────────────

class _KpiBentoGrid extends StatelessWidget {
  const _KpiBentoGrid({required this.computed});

  final AnalyticsComputed computed;

  @override
  Widget build(BuildContext context) {
    final palette = ReportsPalette.of(context);
    final bundle = computed.bundle;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= MobileUi.tabletWidth ? 3 : 2;

    // Period metrics carry a real previous-window comparison; snapshots do not
    // pretend to.
    final ordersTrend = ReportsTrends.forDated(
      all: bundle.orders.orders,
      dateOf: (order) => order.createdAt,
      start: computed.rangeStart,
      end: computed.rangeEnd,
    );
    final tasksTrend = ReportsTrends.forDated(
      all: bundle.tasks,
      dateOf: (task) => task.createdAt ?? task.updatedAt ?? task.dueDate,
      start: computed.rangeStart,
      end: computed.rangeEnd,
    );
    final movementsTrend = ReportsTrends.forDated(
      all: bundle.movements.movements,
      dateOf: (movement) => movement.timestamp,
      start: computed.rangeStart,
      end: computed.rangeEnd,
    );

    final cards = <Widget>[
      ReportsKpiCard(
        label: 'Orders',
        value: '${computed.filteredOrders.length}',
        icon: Icons.shopping_cart_rounded,
        accent: palette.accent(ReportsAccent.indigo),
        trend: ordersTrend,
      ),
      ReportsKpiCard(
        label: 'Tasks',
        value: '${computed.filteredTasks.length}',
        icon: Icons.task_alt_rounded,
        accent: palette.accent(ReportsAccent.violet),
        trend: tasksTrend,
      ),
      ReportsKpiCard(
        label: 'Movements',
        value: '${computed.filteredMovements.length}',
        icon: Icons.swap_horiz_rounded,
        accent: palette.accent(ReportsAccent.sky),
        trend: movementsTrend,
      ),
      ReportsKpiCard(
        label: 'Stock Value',
        value: WmsFormatters.currency(bundle.reports.valuation.costValue),
        icon: Icons.payments_rounded,
        accent: palette.accent(ReportsAccent.emerald),
        trend: const MetricTrend.snapshot(),
        caption: 'At cost, live',
      ),
      ReportsKpiCard(
        label: 'Total Inventory',
        value: WmsFormatters.quantity(
          bundle.inventoryTracking.summary.totalUnits,
        ),
        icon: Icons.inventory_2_rounded,
        accent: palette.accent(ReportsAccent.sky),
        trend: const MetricTrend.snapshot(),
        caption: 'Units on hand',
      ),
      ReportsKpiCard(
        label: 'Low Stock',
        value: '${bundle.inventoryTracking.summary.lowStock}',
        icon: Icons.warning_amber_rounded,
        accent: palette.accent(ReportsAccent.amber),
        trend: const MetricTrend.snapshot(),
        caption: 'Below threshold',
        invertTrend: true,
      ),
      ReportsKpiCard(
        label: 'Expiring Soon',
        value: '${bundle.expiringSoonCount}',
        icon: Icons.event_busy_rounded,
        accent: palette.accent(ReportsAccent.coral),
        trend: const MetricTrend.snapshot(),
        caption: 'Next 30 days',
        invertTrend: true,
      ),
      ReportsKpiCard(
        label: 'Total Products',
        value: '${bundle.products.length}',
        icon: Icons.category_rounded,
        accent: palette.accent(ReportsAccent.indigo),
        trend: const MetricTrend.snapshot(),
        caption: 'Catalogue size',
      ),
      ReportsKpiCard(
        label: 'Warehouses',
        value: '${bundle.warehouses.length}',
        icon: Icons.warehouse_rounded,
        accent: palette.accent(ReportsAccent.slate),
        trend: const MetricTrend.snapshot(),
        caption: 'Active facilities',
      ),
      ReportsKpiCard(
        label: 'Active Users',
        value: '${bundle.activeUsersCount}',
        icon: Icons.verified_user_rounded,
        accent: palette.accent(ReportsAccent.emerald),
        trend: const MetricTrend.snapshot(),
        caption: 'of ${bundle.users.where((u) => !u.archived).length} total',
      ),
    ];

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: ReportsKpiCard.gridExtent,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => cards[index],
        childCount: cards.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pinned tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _PillTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PillTabBarDelegate({required this.child, required this.background});

  final Widget child;
  final Color background;

  static const double _extent = ReportsPillTabBar.height +
      AppSpacing.md +
      AppSpacing.sm;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: background, child: child);
  }

  @override
  bool shouldRebuild(covariant _PillTabBarDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.background != background;
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsLoadingView extends StatelessWidget {
  const _ReportsLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        WmsSkeletonBox(height: 150, radius: ReportsPalette.radiusHero),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: WmsSkeletonBox(height: 148, radius: ReportsPalette.radiusCard),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: WmsSkeletonBox(height: 148, radius: ReportsPalette.radiusCard),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: WmsSkeletonBox(height: 148, radius: ReportsPalette.radiusCard),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: WmsSkeletonBox(height: 148, radius: ReportsPalette.radiusCard),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        WmsSkeletonBox(height: 46, radius: ReportsPalette.radiusPill),
        SizedBox(height: AppSpacing.lg),
        WmsSkeletonBox(height: 240, radius: ReportsPalette.radiusCard),
      ],
    );
  }
}
