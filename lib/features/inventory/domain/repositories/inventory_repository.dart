import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';

abstract class InventoryRepository {
  Future<({List<InventoryItem> items, InventorySummary summary})> getTracking({
    String? query,
    String? warehouseId,
  });

  Future<List<WarehouseOption>> getWarehouses();
}
