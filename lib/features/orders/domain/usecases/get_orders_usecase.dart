import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/orders/domain/repositories/orders_repository.dart';

class GetOrdersUseCase {
  const GetOrdersUseCase(this._repository);

  final OrdersRepository _repository;

  Future<({List<WarehouseOrder> orders, OrderStats stats})> call({
    String? status,
  }) =>
      _repository.getOrders(status: status);
}
