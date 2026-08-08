import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_quick_actions.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_today_summary.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_kpi_strip.dart';

/// Pre-fix KPI card used only to capture the overflow regression golden.
class _LegacyKPIStatCard extends StatelessWidget {
  const _LegacyKPIStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: AppSpacing.iconMd, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

void main() {
  final kpiItems = [
    WmsKpiItem(
      label: 'Products',
      value: '128',
      icon: Icons.category_outlined,
      color: AppColors.primary,
      background: AppColors.primaryLight,
    ),
    WmsKpiItem(
      label: 'Warehouses',
      value: '4',
      icon: Icons.warehouse_outlined,
      color: AppColors.info,
      background: AppColors.infoLight,
    ),
    WmsKpiItem(
      label: 'Orders',
      value: '26',
      icon: Icons.shopping_bag_outlined,
      color: AppColors.accent,
      background: AppColors.accentLight,
    ),
    WmsKpiItem(
      label: 'Low Stock',
      value: '9',
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
      background: AppColors.warningLight,
    ),
    WmsKpiItem(
      label: 'Tasks',
      value: '12',
      icon: Icons.assignment_outlined,
      color: AppColors.primary,
      background: AppColors.primaryLight,
    ),
    WmsKpiItem(
      label: 'Stock Value',
      value: '48,250',
      icon: Icons.payments_outlined,
      color: AppColors.success,
      background: AppColors.successLight,
    ),
  ];

  final quickActions = [
    WmsQuickAction(
      label: 'Receive Stock',
      icon: Icons.download_rounded,
      onTap: () {},
    ),
    WmsQuickAction(
      label: 'Dispatch Stock',
      icon: Icons.upload_rounded,
      onTap: () {},
    ),
    WmsQuickAction(
      label: 'Transfer Stock',
      icon: Icons.swap_horiz_rounded,
      onTap: () {},
    ),
    WmsQuickAction(
      label: 'My Tasks',
      icon: Icons.assignment_outlined,
      onTap: () {},
    ),
    WmsQuickAction(
      label: 'Orders',
      icon: Icons.shopping_cart_outlined,
      onTap: () {},
    ),
    WmsQuickAction(
      label: 'Reports',
      icon: Icons.assessment_outlined,
      onTap: () {},
    ),
  ];

  Future<void> pumpDashboardSection(
    WidgetTester tester, {
    required Size surfaceSize,
    required bool compactQuickActions,
  }) async {
    final contentWidth = surfaceSize.width - (AppSpacing.screenPadding * 2);
    final overflowErrors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed') ||
          message.contains('RenderFlex')) {
        overflowErrors.add(details);
      } else {
        previousHandler?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previousHandler);

    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: SizedBox(
              width: contentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Operations overview',
                    style: ThemeData.light().textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  WmsKpiStrip(items: kpiItems),
                  const SizedBox(height: AppSpacing.sectionGap),
                  WmsQuickActionsSection(
                    compact: compactQuickActions,
                    actions: quickActions,
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                  const WmsTodaySummary(
                    pending: 5,
                    inProgress: 3,
                    completed: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      overflowErrors,
      isEmpty,
      reason: overflowErrors
          .map((e) => e.exceptionAsString())
          .join('\n'),
    );
  }

  group('Dashboard overflow checks', () {
    testWidgets('no overflow at 360x640', (tester) async {
      await pumpDashboardSection(
        tester,
        surfaceSize: const Size(360, 640),
        compactQuickActions: false,
      );
    });

    testWidgets('no overflow at 393x852', (tester) async {
      await pumpDashboardSection(
        tester,
        surfaceSize: const Size(393, 852),
        compactQuickActions: false,
      );
    });

    testWidgets('no overflow at 412x915', (tester) async {
      await pumpDashboardSection(
        tester,
        surfaceSize: const Size(412, 915),
        compactQuickActions: true,
      );
    });

    testWidgets('golden snapshot 360x640 after fix', (tester) async {
      await pumpDashboardSection(
        tester,
        surfaceSize: const Size(360, 640),
        compactQuickActions: false,
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/dashboard_kpi_360_after.png'),
      );
    });

    testWidgets('golden snapshot 393x852 after fix', (tester) async {
      await pumpDashboardSection(
        tester,
        surfaceSize: const Size(393, 852),
        compactQuickActions: false,
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/dashboard_kpi_393_after.png'),
      );
    });

    testWidgets('golden snapshot 360x640 before fix (legacy aspect ratio)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final previousHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          return;
        }
        previousHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousHandler);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: SizedBox(
                width: 360 - (AppSpacing.screenPadding * 2),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.6,
                  children: [
                    for (final item in kpiItems)
                      _LegacyKPIStatCard(
                        label: item.label,
                        value: item.value,
                        icon: item.icon,
                        color: item.color,
                        background: item.background,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      while (tester.takeException() != null) {}
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/dashboard_kpi_360_before.png'),
      );
    });

    testWidgets('golden snapshot 412x915 after fix', (tester) async {
      await pumpDashboardSection(
        tester,
        surfaceSize: const Size(412, 915),
        compactQuickActions: true,
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/dashboard_kpi_412_after.png'),
      );
    });
  });
}
