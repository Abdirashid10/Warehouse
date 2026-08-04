import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/domain/repositories/inventory_repository.dart';

class GetInventoryUseCase {
  const GetInventoryUseCase(this._repository);

  final InventoryRepository _repository;

  Future<({List<InventoryItem> items, InventorySummary summary})> call({
    String? query,
    String? warehouseId,
  }) =>
      _repository.getTracking(query: query, warehouseId: warehouseId);
}
