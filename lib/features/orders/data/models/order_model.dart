import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';

class OrderModel {
  OrderModel({
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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = <OrderLineItem>[];
    if (itemsRaw is List) {
      for (final raw in itemsRaw) {
        if (raw is! Map<String, dynamic>) continue;
        final product = raw['product'];
        items.add(
          OrderLineItem(
            productName: product is Map
                ? (product['name'] ?? '').toString()
                : (raw['product_name'] ?? '').toString(),
            sku: product is Map
                ? (product['sku'] ?? '').toString()
                : (raw['sku'] ?? '').toString(),
            quantity: raw['quantity'] as num? ?? 0,
          ),
        );
      }
    }

    return OrderModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      orderNumber: (json['order_number'] ?? json['orderNumber'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      customerName: (json['customer_name'] ?? json['customerName'] ?? '').toString(),
      itemCount: items.isNotEmpty
          ? items.length
          : (json['total_items'] ?? json['items']?.length ?? 0) as int,
      grandTotal: json['grand_total'] ??
          json['grandTotal'] ??
          json['total_amount'] ??
          0,
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
      phoneNumber: json['phone_number']?.toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      priority: json['priority']?.toString(),
      expectedDeliveryDate: DateTime.tryParse(
        (json['expected_delivery_date'] ?? '').toString(),
      ),
      items: items,
    );
  }

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

  WarehouseOrder toEntity() => WarehouseOrder(
        id: id,
        orderNumber: orderNumber,
        status: status,
        customerName: customerName,
        itemCount: itemCount,
        grandTotal: grandTotal,
        createdAt: createdAt,
        phoneNumber: phoneNumber,
        deliveryAddress: deliveryAddress,
        priority: priority,
        expectedDeliveryDate: expectedDeliveryDate,
        items: items,
      );
}
