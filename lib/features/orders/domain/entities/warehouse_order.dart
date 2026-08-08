import 'package:equatable/equatable.dart';

class WarehouseOrder extends Equatable {
  const WarehouseOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.itemCount,
    required this.grandTotal,
    required this.createdAt,
    this.phoneNumber,
    this.deliveryAddress,
    this.priority,
    this.expectedDeliveryDate,
    this.items = const [],
  });

  final String id;
  final String orderNumber;
  final String status;
  final String customerName;
  final int itemCount;
  final num grandTotal;
  final DateTime? createdAt;
  final String? phoneNumber;
  final String? deliveryAddress;
  final String? priority;
  final DateTime? expectedDeliveryDate;
  final List<OrderLineItem> items;

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        customerName,
        itemCount,
        grandTotal,
        createdAt,
        phoneNumber,
        deliveryAddress,
        priority,
        expectedDeliveryDate,
        items,
      ];
}

class OrderLineItem extends Equatable {
  const OrderLineItem({
    required this.productName,
    required this.sku,
    required this.quantity,
  });

  final String productName;
  final String sku;
  final num quantity;

  @override
  List<Object?> get props => [productName, sku, quantity];
}

class OrderStats extends Equatable {
  const OrderStats({
    required this.actionable,
    required this.processing,
    required this.packed,
    required this.shipped,
  });

  final int actionable;
  final int processing;
  final int packed;
  final int shipped;

  @override
  List<Object?> get props => [actionable, processing, packed, shipped];
}
