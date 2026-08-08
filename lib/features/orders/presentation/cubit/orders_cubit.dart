import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/orders/domain/repositories/orders_repository.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/repositories/products_repository.dart';

enum OrdersDateFilter { all, today, week, month, year }

class OrdersViewState {
  const OrdersViewState({
    required this.orders,
    required this.stats,
    required this.inventory,
    required this.products,
    required this.notifications,
    this.statusFilter,
    this.warehouseFilter,
    this.dateFilter = OrdersDateFilter.all,
    this.searchQuery = '',
  });

  final List<WarehouseOrder> orders;
  final OrderStats stats;
  final List<InventoryItem> inventory;
  final List<Product> products;
  final List<AppNotification> notifications;
  final String? statusFilter;
  final String? warehouseFilter;
  final OrdersDateFilter dateFilter;
  final String searchQuery;

  int get totalOrders => orders.length;

  int get pendingOrders =>
      orders.where((o) => o.status == WmsOrderStatuses.pending).length;

  int get processingOrders =>
      orders.where((o) => o.status == WmsOrderStatuses.processing).length;

  int get shippedOrders =>
      orders.where((o) => o.status == WmsOrderStatuses.shipped).length;

  int get deliveredOrders =>
      orders.where((o) => o.status == WmsOrderStatuses.delivered).length;

  int get cancelledOrders =>
      orders.where((o) => o.status.toLowerCase() == 'cancelled').length;

  List<String> get warehouses {
    final set = <String>{};
    for (final order in orders) {
      final warehouse = inferredWarehouse(order);
      if (warehouse.isNotEmpty) set.add(warehouse);
    }
    final list = set.toList()..sort();
    return list;
  }

  String inferredWarehouse(WarehouseOrder order) {
    if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) {
      return order.deliveryAddress!;
    }
    for (final line in order.items) {
      final item = inventory.where((i) => i.sku == line.sku).cast<InventoryItem?>().firstWhere(
            (e) => e != null,
            orElse: () => null,
          );
      if (item != null) return item.warehouseName;
    }
    return 'Main Warehouse';
  }

  List<AppNotification> get orderNotifications => notifications.where((n) {
        final text = '${n.title} ${n.message} ${n.type}'.toLowerCase();
        return text.contains('order');
      }).toList();

  List<WarehouseOrder> get filtered {
    final now = DateTime.now();
    return orders.where((order) {
      if (statusFilter != null &&
          statusFilter!.isNotEmpty &&
          order.status != statusFilter) {
        return false;
      }
      if (warehouseFilter != null && warehouseFilter!.isNotEmpty) {
        if (inferredWarehouse(order) != warehouseFilter) return false;
      }
      if (dateFilter != OrdersDateFilter.all) {
        final created = order.createdAt;
        if (created == null) return false;
        switch (dateFilter) {
          case OrdersDateFilter.today:
            if (created.year != now.year ||
                created.month != now.month ||
                created.day != now.day) {
              return false;
            }
          case OrdersDateFilter.week:
            final start = DateTime(now.year, now.month, now.day)
                .subtract(const Duration(days: 6));
            if (created.isBefore(start)) return false;
          case OrdersDateFilter.month:
            if (created.year != now.year || created.month != now.month) {
              return false;
            }
          case OrdersDateFilter.year:
            if (created.year != now.year) return false;
          case OrdersDateFilter.all:
            break;
        }
      }
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return order.orderNumber.toLowerCase().contains(q) ||
          order.customerName.toLowerCase().contains(q) ||
          order.status.toLowerCase().contains(q) ||
          inferredWarehouse(order).toLowerCase().contains(q);
    }).toList();
  }
}

class OrdersCubit extends Cubit<ResourceState<OrdersViewState>> {
  OrdersCubit(
    this._repository,
    this._inventoryRepository,
    this._productsRepository,
    this._notificationsRepository,
  ) : super(const ResourceState.initial());

  final OrdersRepository _repository;
  final InventoryRepository _inventoryRepository;
  final ProductsRepository _productsRepository;
  final NotificationsRepository _notificationsRepository;

  Future<void> load({String? status}) async {
    emit(const ResourceState.loading());
    try {
      final results = await Future.wait([
        _repository.getOrders(status: status),
        _inventoryRepository.getTracking(),
        _productsRepository.getProducts(),
        _notificationsRepository.getNotifications(),
      ]);
      final result =
          results[0] as ({List<WarehouseOrder> orders, OrderStats stats});
      final inventory =
          (results[1]
                  as ({List<InventoryItem> items, InventorySummary summary}))
              .items;
      final products = results[2] as List<Product>;
      final notifications =
          (results[3] as ({List<AppNotification> items, int unreadCount})).items;
      emit(
        ResourceState.success(
          OrdersViewState(
            orders: result.orders,
            stats: result.stats,
            statusFilter: status,
            inventory: inventory,
            products: products,
            notifications: notifications,
          ),
        ),
      );
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load orders'));
    }
  }

  void setSearch(String query) {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.success(current.copyWith(searchQuery: query)));
  }

  void setStatusFilter(String? status) {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.success(current.copyWith(statusFilter: status)));
  }

  void setWarehouseFilter(String? warehouse) {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.success(current.copyWith(warehouseFilter: warehouse)));
  }

  void setDateFilter(OrdersDateFilter filter) {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.success(current.copyWith(dateFilter: filter)));
  }

  Future<void> refresh() => load(status: state.data?.statusFilter);
}

extension on OrdersViewState {
  OrdersViewState copyWith({
    List<WarehouseOrder>? orders,
    OrderStats? stats,
    List<InventoryItem>? inventory,
    List<Product>? products,
    List<AppNotification>? notifications,
    String? statusFilter,
    String? warehouseFilter,
    OrdersDateFilter? dateFilter,
    String? searchQuery,
  }) {
    return OrdersViewState(
      orders: orders ?? this.orders,
      stats: stats ?? this.stats,
      inventory: inventory ?? this.inventory,
      products: products ?? this.products,
      notifications: notifications ?? this.notifications,
      statusFilter: statusFilter ?? this.statusFilter,
      warehouseFilter: warehouseFilter ?? this.warehouseFilter,
      dateFilter: dateFilter ?? this.dateFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
