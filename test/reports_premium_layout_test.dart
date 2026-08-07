import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_analytics_cubit.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_sample_data.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_trends.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_atoms.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_charts.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_premium_theme.dart';
import 'package:logisticsmobile/features/reports/presentation/widgets/reports_tab_views.dart';

void main() {
  AnalyticsComputed computedFor(AnalyticsDatePreset preset) =>
      AnalyticsComputer.compute(
        bundle: ReportsSampleData.build(),
        preset: preset,
        customRange: null,
      );

  final actions = ReportsTabActions(
    onWidenPeriod: () {},
    onRefresh: () async {},
  );

  /// Bounded settle: a hung animation fails in seconds instead of stalling the
  /// suite for the framework's ten-minute default.
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

  Future<void> pumpSurfaces(
    WidgetTester tester, {
    required Size surfaceSize,
    required ThemeData theme,
  }) async {
    final errors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousHandler);

    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final computed = computedFor(AnalyticsDatePreset.year);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ListView(
            children: [
              ReportsHeroBanner(
                title: 'Analytics Center',
                subtitle:
                    'Organization-wide business intelligence and operational KPIs',
                child: ReportsPeriodSelector<AnalyticsDatePreset>(
                  options: const [
                    ReportsPeriodOption(
                      value: AnalyticsDatePreset.today,
                      label: 'Today',
                      icon: Icons.today_rounded,
                    ),
                    ReportsPeriodOption(
                      value: AnalyticsDatePreset.year,
                      label: 'This Year',
                      icon: Icons.calendar_month_rounded,
                    ),
                  ],
                  selected: AnalyticsDatePreset.year,
                  onSelected: (_) {},
                  rangeLabel: computed.rangeLabel,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: ReportsNoticeChip(
                  icon: Icons.science_outlined,
                  headline: 'Showing illustrative sample data',
                  detail: 'The analytics service is unreachable.',
                  status: ReportsStatus.warning,
                  initiallyExpanded: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: ReportsKpiCard.gridExtent,
                      child: Row(
                        children: [
                          Expanded(
                            child: ReportsKpiCard(
                              label: 'Orders',
                              value: '128',
                              icon: Icons.shopping_cart_rounded,
                              accent: const Color(0xFF4338CA),
                              trend: ReportsTrends.forDated(
                                all: computed.bundle.orders.orders,
                                dateOf: (o) => o.createdAt,
                                start: computed.rangeStart,
                                end: computed.rangeEnd,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: ReportsKpiCard(
                              label: 'Stock Value',
                              value: r'$1,284,000',
                              icon: Icons.payments_rounded,
                              accent: Color(0xFF059669),
                              trend: MetricTrend.snapshot(),
                              caption: 'At cost, live',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 1400,
                  child: ReportsInventoryTab(
                    computed: computed,
                    actions: actions,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 1400,
                  child: ReportsOrdersTab(computed: computed, actions: actions),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 1400,
                  child:
                      ReportsWarehouseTab(computed: computed, actions: actions),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 1400,
                  child:
                      ReportsMovementsTab(computed: computed, actions: actions),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 1200,
                  child: ReportsTasksTab(computed: computed, actions: actions),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 1200,
                  child: ReportsUsersTab(computed: computed, actions: actions),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 900,
                  child: ReportsExportTab(rangeLabel: 'This Year'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);

    expect(
      errors,
      isEmpty,
      reason: errors.map((e) => e.exceptionAsString()).join('\n'),
    );
  }

  for (final width in const [320.0, 360.0, 393.0, 412.0]) {
    testWidgets('reports surfaces render clean in light theme at ${width}dp',
        (tester) async {
      await pumpSurfaces(
        tester,
        surfaceSize: Size(width, 2000),
        theme: AppTheme.light,
      );
    });

    testWidgets('reports surfaces render clean in dark theme at ${width}dp',
        (tester) async {
      await pumpSurfaces(
        tester,
        surfaceSize: Size(width, 2000),
        theme: AppTheme.dark,
      );
    });
  }

  group('trend integrity', () {
    test('snapshot metrics never fabricate a delta', () {
      const trend = MetricTrend.snapshot();
      expect(trend.comparable, isFalse);
      expect(trend.changeLabel, isNull);
      expect(trend.isNewActivity, isFalse);
    });

    test('a rise against the previous window reads as up', () {
      final now = DateTime(2026, 3, 20, 12);
      final start = DateTime(2026, 3, 15);
      final end = DateTime(2026, 3, 21, 23, 59, 59);
      // Two items in the current window, one in the previous.
      final dates = [now, now.subtract(const Duration(days: 1)), DateTime(2026, 3, 10)];

      final trend = ReportsTrends.forDated<DateTime>(
        all: dates,
        dateOf: (d) => d,
        start: start,
        end: end,
      );

      expect(trend.comparable, isTrue);
      expect(trend.currentCount, 2);
      expect(trend.previousCount, 1);
      expect(trend.direction, TrendDirection.up);
      expect(trend.changeLabel, '+100%');
    });

    test('activity with no prior period is flagged, not shown as +100%', () {
      final trend = ReportsTrends.forDated<DateTime>(
        all: [DateTime(2026, 3, 18)],
        dateOf: (d) => d,
        start: DateTime(2026, 3, 15),
        end: DateTime(2026, 3, 21, 23, 59, 59),
      );

      expect(trend.currentCount, 1);
      expect(trend.previousCount, 0);
      expect(trend.changePercent, isNull);
      expect(trend.isNewActivity, isTrue);
      expect(trend.changeLabel, isNull);
    });
  });

  group('series folding', () {
    test('keeps the top identities and names the overflow', () {
      final folded = ReportsSeries.fold([
        const MapEntry('A', 10),
        const MapEntry('B', 9),
        const MapEntry('C', 8),
        const MapEntry('D', 7),
        const MapEntry('E', 6),
        const MapEntry('F', 5),
        const MapEntry('G', 4),
      ]);

      expect(folded.length, ReportsPalette.maxSeries);
      expect(folded.first.label, 'A');
      expect(folded.last.label, 'Other (3)');
      expect(folded.last.value, 15);
    });

    test('drops non-positive values and leaves short lists intact', () {
      final folded = ReportsSeries.fold([
        const MapEntry('A', 3),
        const MapEntry('B', 0),
      ]);

      expect(folded.length, 1);
      expect(folded.single.label, 'A');
    });
  });

  testWidgets('period selector reveals quick filters and reports a choice',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    AnalyticsDatePreset? chosen;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ReportsPeriodSelector<AnalyticsDatePreset>(
            options: const [
              ReportsPeriodOption(
                value: AnalyticsDatePreset.today,
                label: 'Today',
                icon: Icons.today_rounded,
              ),
              ReportsPeriodOption(
                value: AnalyticsDatePreset.month,
                label: 'This Month',
                icon: Icons.calendar_view_month_rounded,
              ),
            ],
            selected: AnalyticsDatePreset.month,
            onSelected: (value) => chosen = value,
            rangeLabel: 'This Month',
          ),
        ),
      ),
    );
    await settle(tester);

    // Collapsed: the summary is visible, the quick filters are not.
    expect(find.text('REPORTING PERIOD'), findsOneWidget);
    expect(find.text('Today'), findsNothing);

    await tester.tap(find.text('REPORTING PERIOD'));
    await settle(tester);

    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await settle(tester);

    expect(chosen, AnalyticsDatePreset.today);
  });

  testWidgets('empty tab offers actions that widen the period', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var widened = false;
    final emptyBundle = ReportsAnalyticsBundle(
      reports: ReportsSampleData.build().reports,
      products: const [],
      inventoryTracking: ReportsSampleData.build().inventoryTracking,
      warehouses: const [],
      orders: (orders: const [], stats: ReportsSampleData.build().orders.stats),
      users: const [],
      tasks: const [],
      movements: (
        movements: const [],
        stats: ReportsSampleData.build().movements.stats,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ReportsOrdersTab(
            computed: AnalyticsComputer.compute(
              bundle: emptyBundle,
              preset: AnalyticsDatePreset.today,
              customRange: null,
            ),
            actions: ReportsTabActions(
              onWidenPeriod: () => widened = true,
              onRefresh: () async {},
            ),
          ),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('No orders in Today'), findsOneWidget);
    expect(find.text('Widen to this year'), findsOneWidget);

    await tester.tap(find.text('Widen to this year'));
    await tester.pump();

    expect(widened, isTrue);
  });

  testWidgets('pill tab bar drives the page and survives narrow widths',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final errors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousHandler);

    const tabs = [
      ReportsTabSpec(label: 'Inventory', icon: Icons.inventory_2_rounded),
      ReportsTabSpec(label: 'Orders', icon: Icons.shopping_cart_rounded),
      ReportsTabSpec(label: 'Warehouse', icon: Icons.warehouse_rounded),
      ReportsTabSpec(label: 'Stock', icon: Icons.swap_horiz_rounded),
      ReportsTabSpec(label: 'Tasks', icon: Icons.task_alt_rounded),
      ReportsTabSpec(label: 'Users', icon: Icons.groups_rounded),
      ReportsTabSpec(label: 'Export', icon: Icons.ios_share_rounded),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ReportsPillTabBar(
                        controller: controller,
                        tabs: tabs,
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: controller,
                        children: [
                          for (final tab in tabs) Center(child: Text(tab.label)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Inventory'), findsNWidgets(2)); // tab + page

    await tester.tap(find.text('Orders'));
    await settle(tester);

    expect(find.text('Orders'), findsNWidgets(2));
    expect(
      errors,
      isEmpty,
      reason: errors.map((e) => e.exceptionAsString()).join('\n'),
    );
  });

  testWidgets('donut legend selection drives the centre readout',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: ReportsDonutChart(
              data: [
                ReportsDatum(label: 'Delivered', value: 30),
                ReportsDatum(label: 'Open', value: 10),
              ],
              centerLabel: 'orders',
            ),
          ),
        ),
      ),
    );
    await settle(tester);

    // Total in the centre, both identities labelled in the legend.
    expect(find.text('40'), findsOneWidget);
    expect(find.text('orders'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);

    await tester.tap(find.text('Delivered'));
    await settle(tester);

    expect(find.text('Delivered · 75%'), findsOneWidget);
    expect(find.text('30'), findsWidgets);
  });
}
