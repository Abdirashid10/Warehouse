import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';

abstract class OrdersRepository {
  Future<({List<WarehouseOrder> orders, OrderStats stats})> getOrders({
    String? status,
  });

  Future<WarehouseOrder> getOrder(String id);

  Future<WarehouseOrder> updateOrderStatus({
    required String id,
    required String status,
  });
}
