import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouses_enterprise_widgets.dart';

void main() {
  const warehouses = [
    Warehouse(
      id: 'w1',
      name: 'Bakaaro',
      location: 'Mogadishu — Bakaaro Market District',
      capacity: 12000,
      staffCount: 14,
      totalUnits: 11400,
      utilization: 95,
      lineCount: 320,
      assignedStaff: [
        WarehouseStaffMember(id: 's1', displayName: 'Ayaan Hassan'),
        WarehouseStaffMember(id: 's2', displayName: 'Mohamed Abdullahi Warsame'),
      ],
    ),
    Warehouse(
      id: 'w2',
      name: 'Madiina Distribution Center',
      location: 'Madiina',
      capacity: 8000,
      staffCount: 7,
      totalUnits: 4800,
      utilization: 60,
      lineCount: 118,
    ),
    Warehouse(
      id: 'w3',
      name: 'Suuqbacaad',
      location: 'Suuqbacaad',
      capacity: 5000,
      staffCount: 3,
      totalUnits: 900,
      utilization: 18,
      lineCount: 42,
    ),
  ];

  final summary = WarehousesSummary.fromWarehouses(warehouses);
  final rankings = WarehousePerformanceRankings.fromWarehouses(warehouses);

  Future<void> pumpWarehousesSurfaces(
    WidgetTester tester, {
    required Size surfaceSize,
    required ThemeData theme,
  }) async {
    final overflowErrors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = overflowErrors.add;
    addTearDown(() => FlutterError.onError = previousHandler);

    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final nameController = TextEditingController();
    final locationController = TextEditingController();
    addTearDown(nameController.dispose);
    addTearDown(locationController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              WarehousesEnterpriseHeader(canManage: true, onAdd: () {}),
              const SizedBox(height: 20),
              WarehousesKpiStrip(summary: summary),
              const SizedBox(height: 20),
              WarehousesSearchPanel(
                nameController: nameController,
                locationController: locationController,
                onNameSearch: (_) {},
                onLocationSearch: (_) {},
                activeFilterCount: 1,
                showFilters: true,
                onToggleFilters: () {},
                onClearFilters: () {},
                displayCount: 3,
                totalCount: 3,
              ),
              const SizedBox(height: 12),
              WarehousesFiltersPanel(
                selected: WarehouseCapacityFilter.full,
                onSelected: (_) {},
              ),
              const SizedBox(height: 20),
              for (final warehouse in warehouses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: WarehouseEnterpriseCard(
                    warehouse: warehouse,
                    canManage: true,
                    onView: () {},
                    onEdit: () {},
                    onTransfer: () {},
                    onAssignStaff: () {},
                  ),
                ),
              const WarehousesAnalyticsSection(warehouses: warehouses),
              const SizedBox(height: 20),
              WarehousesPerformanceSection(rankings: rankings),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      overflowErrors,
      isEmpty,
      reason: overflowErrors.map((e) => e.exceptionAsString()).join('\n'),
    );
  }

  const phoneWidths = [320.0, 360.0, 393.0, 412.0];

  for (final width in phoneWidths) {
    testWidgets('warehouses surfaces fit light theme at ${width}dp',
        (tester) async {
      await pumpWarehousesSurfaces(
        tester,
        surfaceSize: Size(width, 2400),
        theme: AppTheme.light,
      );
    });

    testWidgets('warehouses surfaces fit dark theme at ${width}dp',
        (tester) async {
      await pumpWarehousesSurfaces(
        tester,
        surfaceSize: Size(width, 2400),
        theme: AppTheme.dark,
      );
    });
  }

  testWidgets('warehouse card exposes capacity, metrics and actions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: WarehouseEnterpriseCard(
              warehouse: warehouses.first,
              canManage: true,
              onView: () {},
              onEdit: () {},
              onTransfer: () {},
              onAssignStaff: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bakaaro'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('Critical'), findsOneWidget);
    expect(find.text('Full'), findsOneWidget);
    expect(find.text('11,400'), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsOneWidget);
  });

  testWidgets('read-only users only see the view action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: WarehouseEnterpriseCard(
              warehouse: warehouses[1],
              canManage: false,
              onView: () {},
              onEdit: () {},
              onTransfer: () {},
              onAssignStaff: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Details'), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsNothing);
    expect(find.byIcon(Icons.swap_horiz_rounded), findsNothing);
  });

  testWidgets('detail sheet renders capacity and staff', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showWarehouseDetailSheet(context, warehouses.first),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Bakaaro'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.text('Ayaan Hassan'), findsOneWidget);
    expect(find.text('Mohamed Abdullahi Warsame'), findsOneWidget);
  });
}
