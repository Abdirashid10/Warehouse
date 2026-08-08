import 'package:logisticsmobile/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/orders/domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._remote);

  final OrdersRemoteDataSource _remote;

  @override
  Future<({List<WarehouseOrder> orders, OrderStats stats})> getOrders({
    String? status,
  }) async {
    final models = await _remote.fetchOrders(status: status);
    return (
      orders: models.map((m) => m.toEntity()).toList(),
      stats: _remote.computeStats(models),
    );
  }

  @override
  Future<WarehouseOrder> getOrder(String id) async {
    final model = await _remote.fetchOrder(id);
    return model.toEntity();
  }

  @override
  Future<WarehouseOrder> updateOrderStatus({
    required String id,
    required String status,
  }) async {
    final model = await _remote.updateStatus(id: id, status: status);
    return model.toEntity();
  }
}
