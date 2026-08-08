import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/staff_operations_dashboard_body.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/validate_session_usecase.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';

import 'fakes/fake_auth_repository.dart';

/// Layout and formatting contract for the Staff dashboard.
///
/// The grids here previously painted into a fixed 148dp row while their cards
/// measured ~164dp, and every key/value row rendered its label hard against its
/// value ("CustomerFakhrudiin"). Both are asserted directly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();

  WarehouseTask task({
    String id = 't1',
    String status = WmsTaskStatuses.inProgress,
    String priority = 'HIGH',
  }) => WarehouseTask(
    id: id,
    title: 'Cycle count — aisle 4',
    description: 'Count every pallet position in aisle 4.',
    status: status,
    priority: priority,
    taskType: WmsTaskTypes.inventoryCount,
    productName: 'charge',
    warehouseName: 'Bakaaro',
    assignedToName: 'Fakhrudiin',
    dueDate: now.add(const Duration(days: 1)),
    createdAt: now.subtract(const Duration(hours: 5)),
  );

  final order = WarehouseOrder(
    id: 'o1',
    orderNumber: 'ORD-4412',
    customerName: 'Fakhrudiin',
    status: WmsOrderStatuses.packed,
    itemCount: 3,
    grandTotal: 1240,
    createdAt: now.subtract(const Duration(hours: 2)),
  );

  StaffDashboardData buildData() => StaffDashboardData(
    tasks: [
      task(),
      task(id: 't2', status: WmsTaskStatuses.pending, priority: 'MEDIUM'),
      task(id: 't3', status: WmsTaskStatuses.overdue),
    ],
    inventorySummary: const InventorySummary(
      totalUnits: 12840,
      inStock: 96,
      lowStock: 7,
      outOfStock: 2,
    ),
    inventoryItems: const [],
    products: const [],
    movements: const [],
    alerts: const DashboardAlerts(
      lowStockCount: 7,
      outOfStockCount: 2,
      expiredCount: 1,
      expiringSoonCount: 3,
    ),
    warehouseStats: const [
      WarehouseStat(
        id: 'w1',
        name: 'Bakaaro',
        totalUnits: 11400,
        utilization: 95,
        location: 'Mogadishu',
        productCount: 42,
      ),
    ],
    insights: const [
      DashboardInsight(message: 'Low stock on 7 SKUs', severity: 'warning'),
    ],
    recentOrders: [order],
    pendingOrdersCount: 4,
    allOrders: [order],
  );

  Future<List<String>> pumpDashboard(
    WidgetTester tester, {
    required double width,
    required double textScale,
    required ThemeData theme,
  }) async {
    // Overflow errors are collected rather than thrown so every offending
    // box is reported in one run. Everything else is forwarded, so a real
    // crash still fails loudly.
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('google_fonts')) return;
      if (message.contains('overflowed')) {
        overflows.add(message.split('\n').first);
        return;
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await tester.binding.setSurfaceSize(Size(width, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeAuthRepository();
    final authBloc = AuthBloc(
      restoreSession: RestoreSessionUseCase(repository),
      validateSession: ValidateSessionUseCase(repository),
      login: LoginUseCase(repository),
      logout: LogoutUseCase(repository),
    );
    addTearDown(authBloc.close);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: StaffOperationsDashboardBody(
                    data: buildData(),
                    assignedWarehouseName: 'Bakaaro',
                    stockOpsRoute: '/staff/stock-operations',
                    ordersRoute: '/staff/orders',
                    tasksRoute: '/staff/tasks',
                    inventoryRoute: '/staff/inventory',
                    reportsRoute: '/staff/reports',
                    notificationsRoute: '/staff/notifications',
                    onTaskAction: (_, __) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Fixed pumps, never pumpAndSettle: a painted overflow indicator keeps
    // scheduling frames, so settling would spin until the ten-minute cap.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return overflows;
  }

  group('no overflow', () {
    for (final width in const [320.0, 360.0, 393.0, 412.0]) {
      for (final scale in const [1.0, 1.2, 1.3]) {
        testWidgets('staff dashboard fits at ${width.toInt()}dp @ ${scale}x', (
          tester,
        ) async {
          final overflows = await pumpDashboard(
            tester,
            width: width,
            textScale: scale,
            theme: AppTheme.light,
          );
          expect(overflows, isEmpty, reason: overflows.join('\n'));
        });
      }
    }

    testWidgets('staff dashboard fits in dark mode', (tester) async {
      final overflows = await pumpDashboard(
        tester,
        width: 393,
        textScale: 1.2,
        theme: AppTheme.dark,
      );
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });
  });

  group('key/value rows read as labelled pairs', () {
    testWidgets('order and task metadata separate label from value', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        width: 393,
        textScale: 1.0,
        theme: AppTheme.light,
      );

      // The defect rendered these as one run of glyphs ("CustomerFakhrudiin").
      // A labelled pair keeps the label its own Text, punctuated.
      for (final label in ['Customer:', 'Status:', 'Product:', 'Warehouse:']) {
        expect(
          find.text(label),
          findsWidgets,
          reason: '"$label" must render as its own labelled column',
        );
      }

      expect(find.text('Fakhrudiin'), findsWidgets);
      expect(find.text('Bakaaro'), findsWidgets);
      expect(find.text('charge'), findsWidgets);
    });

    testWidgets('no widget concatenates a label with its value', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        width: 393,
        textScale: 1.0,
        theme: AppTheme.light,
      );

      for (final smashed in [
        'CustomerFakhrudiin',
        'StatusPacked',
        'Productcharge',
        'WarehouseBakaaro',
      ]) {
        expect(
          find.text(smashed),
          findsNothing,
          reason: '"$smashed" means the label and value were painted adjacent',
        );
      }
    });
  });
}
