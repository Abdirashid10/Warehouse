import 'package:logisticsmobile/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl(this._remote);

  final InventoryRemoteDataSource _remote;

  @override
  Future<({List<InventoryItem> items, InventorySummary summary})> getTracking({
    String? query,
    String? warehouseId,
  }) async {
    var result = await _remote.fetchTracking(
      query: query,
      warehouseId: warehouseId,
    );
    if (result.items.isEmpty) {
      result = await _remote.fetchInventory(
        query: query,
        warehouseId: warehouseId,
      );
    }
    return (
      items: result.items.map((m) => m.toEntity()).toList(),
      summary: result.summary.toEntity(),
    );
  }

  @override
  Future<List<WarehouseOption>> getWarehouses() => _remote.fetchWarehouses();
}
