import 'package:logisticsmobile/features/warehouses/data/datasources/warehouses_remote_data_source.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/features/warehouses/domain/repositories/warehouses_repository.dart';

class WarehousesRepositoryImpl implements WarehousesRepository {
  WarehousesRepositoryImpl(this._remote);

  final WarehousesRemoteDataSource _remote;

  @override
  Future<List<Warehouse>> getWarehouses() => _remote.fetchWarehouses();

  @override
  Future<Warehouse> createWarehouse({
    required String name,
    required String location,
    required num capacity,
  }) =>
      _remote.createWarehouse(
        name: name,
        location: location,
        capacity: capacity,
      );

  @override
  Future<Warehouse> updateWarehouse({
    required String id,
    String? name,
    String? location,
    num? capacity,
  }) =>
      _remote.updateWarehouse(
        id: id,
        name: name,
        location: location,
        capacity: capacity,
      );
}
