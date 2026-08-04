import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/entities/product_category.dart';
import 'package:logisticsmobile/features/products/domain/entities/products_summary.dart';
import 'package:logisticsmobile/features/products/presentation/widgets/products_enterprise_widgets.dart';

void main() {
  const summary = ProductsSummary(
    total: 128,
    categories: 6,
    lowStock: 9,
    outOfStock: 4,
    expiring: 3,
    totalValue: 48250,
  );

  const categories = [
    ProductCategory(id: '1', name: 'Electronic'),
    ProductCategory(id: '2', name: 'Food & Beverage'),
    ProductCategory(id: '3', name: 'Sports Equipment'),
  ];

  const warehouses = [
    WarehouseOption(id: 'w1', name: 'Bakaaro'),
    WarehouseOption(id: 'w2', name: 'Madiina Distribution Center'),
    WarehouseOption(id: 'w3', name: 'Suuqbacaad'),
  ];

  final products = [
    Product(
      id: 'p1',
      name: 'Premium Wireless Bluetooth Headphones with Noise Cancellation',
      sku: 'ELEC-HP-001',
      category: 'Electronic',
      categoryId: '1',
      unitPrice: 129.99,
      totalStock: 42,
      warehouseCount: 3,
      updatedAt: DateTime(2026, 3, 15),
    ),
    Product(
      id: 'p2',
      name: 'Organic Long-Life Whole Milk 1L',
      sku: 'FOOD-MLK-002',
      category: 'Food & Beverage',
      categoryId: '2',
      unitPrice: 2.49,
      totalStock: 0,
      warehouseCount: 0,
      updatedAt: DateTime(2026, 3, 10),
    ),
    Product(
      id: 'p3',
      name: 'Professional Football Size 5 Match Ball',
      sku: 'SPT-FBL-003',
      category: 'Sports Equipment',
      categoryId: '3',
      unitPrice: 34.50,
      totalStock: 5,
      minStockThreshold: 10,
      warehouseCount: 2,
      updatedAt: DateTime(2026, 3, 1),
    ),
  ];

  Future<void> pumpProductsMobileSection(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    final overflowErrors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed') || message.contains('RenderFlex')) {
        overflowErrors.add(details);
      } else {
        previousHandler?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previousHandler);

    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final searchController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProductsMobileHeader(
                  canManage: true,
                  onAdd: () {},
                ),
                ProductsMobileKpiGrid(summary: summary),
                ProductsMobileSearchSection(
                  searchController: searchController,
                  onSearch: (_) {},
                  categories: categories,
                  warehouses: warehouses,
                  categoryFilterId: null,
                  warehouseFilterId: null,
                  warehouseFilterLoading: false,
                  onCategory: (_) {},
                  onWarehouse: (_) {},
                ),
                ProductsMobileCardList(
                  products: products,
                  canManage: true,
                  isAdmin: true,
                  onView: (_) {},
                  onEdit: (_) {},
                  onStockHistory: () {},
                  onTransfer: () {},
                  onDelete: (_) {},
                ),
              ],
            ),
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

  group('Products mobile overflow checks', () {
    for (final width in [
      MobileUi.minPhoneWidth,
      360.0,
      375.0,
      390.0,
      412.0,
      MobileUi.largePhoneWidth,
      MobileUi.maxPhoneWidth,
    ]) {
      testWidgets('no overflow at ${width.toInt()}x640', (tester) async {
        await pumpProductsMobileSection(
          tester,
          surfaceSize: Size(width, 640),
        );
      });
    }
  });
}
