import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';

abstract class WarehousesRepository {
  Future<List<Warehouse>> getWarehouses();
  Future<Warehouse> createWarehouse({
    required String name,
    required String location,
    required num capacity,
  });
  Future<Warehouse> updateWarehouse({
    required String id,
    String? name,
    String? location,
    num? capacity,
  });
}
