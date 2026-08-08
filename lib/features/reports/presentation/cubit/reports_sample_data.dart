import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/reports/domain/entities/wms_reports_data.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_analytics_cubit.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';

/// Illustrative analytics used only when every backend source is unreachable.
///
/// This exists so the screen can still be demonstrated offline. It is **not** a
/// substitute for real data: the bundle it returns carries
/// `isSampleData: true`, and the screen renders a persistent banner saying so.
///
/// Never remove that flag or the banner. Warehouse analytics drive reorder and
/// dispatch decisions — invented figures that are indistinguishable from live
/// ones are more dangerous than a visible error.
abstract final class ReportsSampleData {
  static ReportsAnalyticsBundle build() {
    final now = DateTime.now();

    DateTime daysAgo(int d) => now.subtract(Duration(days: d));

    final products = <Product>[
      for (var i = 0; i < 6; i++)
        Product(
          id: 'sample-p$i',
          name: _productNames[i],
          sku: 'SAMPLE-${(i + 1).toString().padLeft(4, '0')}',
          category: _categories[i % _categories.length],
          unitCost: 4.5 + i * 3,
          unitPrice: 9.0 + i * 5,
          totalStock: 120 + i * 85,
          warehouseCount: 1 + (i % 3),
          minStockThreshold: 40,
          updatedAt: daysAgo(i),
        ),
    ];

    final inventoryItems = <InventoryItem>[
      for (var i = 0; i < 6; i++)
        InventoryItem(
          id: 'sample-i$i',
          productName: _productNames[i],
          sku: 'SAMPLE-${(i + 1).toString().padLeft(4, '0')}',
          warehouseName: _warehouseNames[i % _warehouseNames.length],
          quantity: 120 + i * 85,
          stockStatus: i == 5
              ? WmsStockStatuses.outOfStock
              : (i == 4 ? WmsStockStatuses.lowStock : WmsStockStatuses.inStock),
          minThreshold: 40,
          expiryDate: i.isEven ? now.add(Duration(days: 20 + i * 15)) : null,
        ),
    ];

    final orders = <WarehouseOrder>[
      for (var i = 0; i < 8; i++)
        WarehouseOrder(
          id: 'sample-o$i',
          orderNumber: 'SAMPLE-ORD-${(i + 1).toString().padLeft(3, '0')}',
          status: _orderStatuses[i % _orderStatuses.length],
          customerName: _customers[i % _customers.length],
          itemCount: 2 + (i % 4),
          grandTotal: 450.0 + i * 275,
          createdAt: daysAgo(i * 2),
          items: const [],
        ),
    ];

    final tasks = <WarehouseTask>[
      for (var i = 0; i < 7; i++)
        WarehouseTask(
          id: 'sample-t$i',
          title: _taskTitles[i % _taskTitles.length],
          status: _taskStatuses[i % _taskStatuses.length],
          priority: _priorities[i % _priorities.length],
          taskType: 'Picking',
          warehouseName: _warehouseNames[i % _warehouseNames.length],
          createdAt: daysAgo(i),
          dueDate: now.add(Duration(days: i)),
        ),
    ];

    final movements = <StockMovement>[
      for (var i = 0; i < 10; i++)
        StockMovement(
          id: 'sample-m$i',
          type: _movementTypes[i % _movementTypes.length],
          productName: _productNames[i % _productNames.length],
          sku: 'SAMPLE-${((i % 6) + 1).toString().padLeft(4, '0')}',
          quantity: 15 + i * 7,
          performedBy: 'Sample User',
          timestamp: daysAgo(i),
        ),
    ];

    return ReportsAnalyticsBundle(
      isSampleData: true,
      reports: WmsReportsData(
        valuation: ValuationReport(
          totalUnits: 1840,
          inventoryLines: inventoryItems.length,
          productCount: products.length,
          costValue: 18420,
          retailValue: 31650,
          estimatedProfit: 13230,
          generatedAt: now,
        ),
        auditSummary: InventoryAuditSummary(
          totalUnits: 1840,
          costValue: 18420,
          retailValue: 31650,
          lineCount: inventoryItems.length,
          warehouseCount: _warehouseNames.length,
          generatedAt: now,
        ),
      ),
      products: products,
      inventoryTracking: (
        items: inventoryItems,
        summary: const InventorySummary(
          totalUnits: 1840,
          inStock: 4,
          lowStock: 1,
          outOfStock: 1,
        ),
      ),
      warehouses: [
        for (var i = 0; i < _warehouseNames.length; i++)
          Warehouse(
            id: 'sample-w$i',
            name: _warehouseNames[i],
            location: _locations[i],
            capacity: 5000 + i * 1500,
            staffCount: 6 + i * 2,
            totalUnits: 620 + i * 310,
            utilization: 42 + i * 12,
            lineCount: 2,
          ),
      ],
      orders: (
        orders: orders,
        stats: const OrderStats(
          actionable: 3,
          processing: 2,
          packed: 1,
          shipped: 2,
        ),
      ),
      users: const [],
      tasks: tasks,
      movements: (
        movements: movements,
        stats: const MovementStats(
          total: 10,
          inbound: 4,
          outbound: 3,
          transfers: 2,
          adjustments: 1,
        ),
      ),
    );
  }

  static const _productNames = [
    'Ballpoint Pen (Box of 50)',
    'A4 Copier Paper Ream',
    'Stainless Water Bottle 1L',
    'Wireless Optical Mouse',
    'Green Tea Bags 200ct',
    'Desk Organiser Tray',
  ];

  static const _categories = ['Stationery', 'Electronics', 'Food', 'Homeware'];

  static const _warehouseNames = [
    'Central Distribution Center',
    'North Warehouse',
    'South Depot',
  ];

  static const _locations = ['Mogadishu', 'Hargeisa', 'Kismayo'];

  static const _customers = [
    'Acme Corporation',
    'Nordwind Traders',
    'Globex Industries',
    'Initech Supplies',
  ];

  static const _orderStatuses = [
    WmsOrderStatuses.pending,
    WmsOrderStatuses.processing,
    WmsOrderStatuses.packed,
    WmsOrderStatuses.shipped,
    WmsOrderStatuses.delivered,
  ];

  static const _taskTitles = [
    'Pick order for dispatch',
    'Cycle count aisle B',
    'Restock shelf 14',
    'Verify inbound delivery',
  ];

  static const _taskStatuses = [
    WmsTaskStatuses.pending,
    WmsTaskStatuses.accepted,
    WmsTaskStatuses.inProgress,
    WmsTaskStatuses.completed,
  ];

  static const _priorities = ['High', 'Medium', 'Low'];

  static const _movementTypes = [
    WmsMovementTypes.inbound,
    WmsMovementTypes.outbound,
    WmsMovementTypes.transfer,
  ];
}
