import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:logisticsmobile/features/inventory/domain/usecases/get_inventory_usecase.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/orders/domain/repositories/orders_repository.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/repositories/products_repository.dart';
import 'package:logisticsmobile/features/inventory/presentation/utils/inventory_metrics.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/stock_operations/domain/repositories/movements_repository.dart';

/// Sort fields for enterprise inventory product lists.
enum InventorySortField {
  name,
  quantity,
  stockLevel,
  warehouse,
  lastUpdated,
}

class InventoryViewState {
  const InventoryViewState({
    required this.items,
    required this.summary,
    required this.warehouses,
    required this.products,
    required this.movements,
    required this.orders,
    this.searchQuery = '',
    this.warehouseId,
    this.categoryFilter,
    this.stockFilter,
    this.sortField = InventorySortField.name,
    this.sortAscending = true,
    this.page = 1,
    this.pageSize = 20,
  });

  final List<InventoryItem> items;
  final InventorySummary summary;
  final List<WarehouseOption> warehouses;
  final List<Product> products;
  final List<StockMovement> movements;
  final List<WarehouseOrder> orders;
  final String searchQuery;
  final String? warehouseId;
  final String? categoryFilter;
  final String? stockFilter;
  final InventorySortField sortField;
  final bool sortAscending;
  final int page;
  final int pageSize;

  Map<String, Product> get productsBySku => {for (final p in products) p.sku: p};

  String categoryFor(InventoryItem item) =>
      productsBySku[item.sku]?.category ?? 'Uncategorized';

  num unitCostFor(InventoryItem item) => productsBySku[item.sku]?.unitCost ?? 0;

  num stockValueFor(InventoryItem item) => item.quantity * unitCostFor(item);

  /// Available = on-hand minus quantities on open orders for this SKU.
  num availableQuantityFor(InventoryItem item) {
    const openKeywords = [
      'pending',
      'processing',
      'progress',
      'accepted',
      'packed',
      'confirmed',
    ];
    num reserved = 0;
    for (final order in orders) {
      final status = order.status.toLowerCase();
      if (status.contains('deliver') ||
          status.contains('complet') ||
          status.contains('cancel')) {
        continue;
      }
      if (!openKeywords.any(status.contains)) continue;
      for (final line in order.items) {
        if (line.sku == item.sku) reserved += line.quantity;
      }
    }
    final available = item.quantity - reserved;
    return available < 0 ? 0 : available;
  }

  num reservedQuantityFor(InventoryItem item) {
    final reserved = item.quantity - availableQuantityFor(item);
    return reserved < 0 ? 0 : reserved;
  }

  num damagedQuantityFor(InventoryItem item) => item.damagedQuantity ?? 0;

  List<InventoryItem> get filtered {
    final query = searchQuery.trim().toLowerCase();
    return items.where((item) {
      if (query.isNotEmpty) {
        final sku = item.sku.toLowerCase();
        final name = item.productName.toLowerCase();
        final category = categoryFor(item).toLowerCase();
        final barcode = item.sku.toLowerCase();
        final warehouse = item.warehouseName.toLowerCase();
        if (!sku.contains(query) &&
            !name.contains(query) &&
            !category.contains(query) &&
            !barcode.contains(query) &&
            !warehouse.contains(query)) {
          return false;
        }
      }
      if (warehouseId != null &&
          warehouseId!.isNotEmpty &&
          item.warehouseId != warehouseId) {
        return false;
      }
      if (categoryFilter != null &&
          categoryFilter!.isNotEmpty &&
          categoryFor(item) != categoryFilter) {
        return false;
      }
      if (stockFilter == 'in' && item.stockStatus != WmsStockStatuses.inStock) {
        return false;
      }
      if (stockFilter == 'low' && item.stockStatus != WmsStockStatuses.lowStock) {
        return false;
      }
      if (stockFilter == 'out' &&
          item.stockStatus != WmsStockStatuses.outOfStock) {
        return false;
      }
      if (stockFilter == 'expired') {
        final expiry = item.expiryDate;
        if (expiry == null || !expiry.isBefore(DateTime.now())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<String> get categories =>
      filtered
          .map(categoryFor)
          .toSet()
          .where((c) => c.isNotEmpty)
          .toList()
        ..sort();

  static const _priorityCategories = [
    'Drink',
    'Electronics',
    'Electronic',
    'Food',
    'Sports',
    'Mobile',
  ];

  /// All catalog categories for filter chips (web parity).
  List<String> get allCategories {
    final fromItems = items.map(categoryFor).where((c) => c.isNotEmpty).toSet();
    final ordered = <String>[];
    for (final name in _priorityCategories) {
      final match = fromItems.where((c) => c.toLowerCase() == name.toLowerCase());
      if (match.isNotEmpty) {
        ordered.add(match.first);
      }
    }
    final remaining = fromItems.where((c) => !ordered.contains(c)).toList()..sort();
    ordered.addAll(remaining);
    return ordered;
  }

  int get expiredCount => InventoryMetrics.expiredCount(items);

  int get expiringSoonCount =>
      InventoryMetrics.expiringWithinDays(items, days: 7);

  int get expiring30DaysCount =>
      InventoryMetrics.expiringWithinDays(items, days: 30);

  int get safeCount => InventoryMetrics.safeCount(items);

  List<InventoryItem> get sortedFiltered {
    final list = List<InventoryItem>.from(filtered);
    list.sort((a, b) {
      final cmp = switch (sortField) {
        InventorySortField.name => a.productName.toLowerCase().compareTo(
              b.productName.toLowerCase(),
            ),
        InventorySortField.quantity => a.quantity.compareTo(b.quantity),
        InventorySortField.stockLevel =>
          _stockLevelRank(a).compareTo(_stockLevelRank(b)),
        InventorySortField.warehouse => a.warehouseName
            .toLowerCase()
            .compareTo(b.warehouseName.toLowerCase()),
        InventorySortField.lastUpdated => _lastUpdatedMillis(a)
            .compareTo(_lastUpdatedMillis(b)),
      };
      if (cmp != 0) return sortAscending ? cmp : -cmp;
      return a.productName.compareTo(b.productName);
    });
    return list;
  }

  int _stockLevelRank(InventoryItem item) {
    final expiry = item.expiryDate;
    if (expiry != null && expiry.isBefore(DateTime.now())) return 0;
    return switch (item.stockStatus) {
      WmsStockStatuses.outOfStock => 1,
      WmsStockStatuses.lowStock => 2,
      _ => 3,
    };
  }

  int _lastUpdatedMillis(InventoryItem item) {
    DateTime? latest;
    for (final m in movements) {
      if (m.sku != item.sku && m.productName != item.productName) continue;
      final ts = m.timestamp;
      if (ts == null) continue;
      if (latest == null || ts.isAfter(latest)) latest = ts;
    }
    return latest?.millisecondsSinceEpoch ?? 0;
  }

  int get uniqueWarehouseCount {
    final names = items.map((i) => i.warehouseName).toSet();
    if (warehouses.isNotEmpty) return warehouses.length;
    return names.length;
  }

  List<InventoryItem> get pageItems {
    final list = sortedFiltered;
    final start = (page - 1) * pageSize;
    if (start >= list.length) return const [];
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get totalPages {
    final count = filtered.length;
    if (count == 0) return 1;
    return (count / pageSize).ceil();
  }

  bool get hasMore => page < totalPages;

  num get stockValueEstimate {
    num total = 0;
    for (final item in items) {
      total += stockValueFor(item);
    }
    return total;
  }
}

class InventoryCubit extends Cubit<ResourceState<InventoryViewState>> {
  InventoryCubit(
    this._getInventory,
    this._repository,
    this._productsRepository,
    this._movementsRepository,
    this._ordersRepository,
  ) : super(const ResourceState.initial());

  final GetInventoryUseCase _getInventory;
  final InventoryRepository _repository;
  final ProductsRepository _productsRepository;
  final MovementsRepository _movementsRepository;
  final OrdersRepository _ordersRepository;

  Future<void> load() async {
    emit(const ResourceState.loading());
    try {
      final warehouses = await _repository.getWarehouses();
      await _fetch(warehouses: warehouses);
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load inventory'));
    }
  }

  Future<void> _fetch({List<WarehouseOption>? warehouses}) async {
    final current = state.data;
    final results = await Future.wait([
      _getInventory(
        query: current?.searchQuery,
        warehouseId: current?.warehouseId,
      ),
      _productsRepository.getProducts(),
      _movementsRepository.getMovements(),
      _ordersRepository.getOrders(),
    ]);
    final result =
        results[0] as ({List<InventoryItem> items, InventorySummary summary});
    final products = results[1] as List<Product>;
    final movements =
        (results[2] as ({List<StockMovement> movements, MovementStats stats}))
            .movements;
    final orders =
        (results[3] as ({List<WarehouseOrder> orders, OrderStats stats})).orders;

    emit(
      ResourceState.success(
        InventoryViewState(
          items: result.items,
          summary: result.summary,
          warehouses: warehouses ?? current?.warehouses ?? [],
          products: products,
          movements: movements,
          orders: orders,
          searchQuery: current?.searchQuery ?? '',
          warehouseId: current?.warehouseId,
          categoryFilter: current?.categoryFilter,
          stockFilter: current?.stockFilter,
          page: current?.page ?? 1,
        ),
      ),
    );
  }

  Future<void> setSearch(String query) async {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.success(current.copyWith(searchQuery: query, page: 1)));
    await _reloadTracking();
  }

  Future<void> setWarehouse(String? warehouseId) async {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.success(current.copyWith(warehouseId: warehouseId, page: 1)));
    await _reloadTracking();
  }

  void setCategory(String? category) {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.success(current.copyWith(categoryFilter: category, page: 1)));
  }

  void setStockFilter(String? filter) {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.success(current.copyWith(stockFilter: filter, page: 1)));
  }

  void setSort(InventorySortField field) {
    final current = state.data;
    if (current == null) return;
    final ascending = current.sortField == field ? !current.sortAscending : true;
    emit(
      ResourceState.success(
        current.copyWith(sortField: field, sortAscending: ascending, page: 1),
      ),
    );
  }

  void nextPage() {
    final current = state.data;
    if (current == null || !current.hasMore) return;
    emit(ResourceState.success(current.copyWith(page: current.page + 1)));
  }

  void prevPage() {
    final current = state.data;
    if (current == null || current.page <= 1) return;
    emit(ResourceState.success(current.copyWith(page: current.page - 1)));
  }

  Future<void> _reloadTracking() async {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.loading(data: current));
    try {
      final result = await _getInventory(
        query: current.searchQuery.isEmpty ? null : current.searchQuery,
        warehouseId: current.warehouseId,
      );
      emit(
        ResourceState.success(
          current.copyWith(items: result.items, summary: result.summary),
        ),
      );
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: current,
      ));
    }
  }

  Future<void> refresh() => load();
}

extension on InventoryViewState {
  InventoryViewState copyWith({
    List<InventoryItem>? items,
    InventorySummary? summary,
    List<WarehouseOption>? warehouses,
    List<Product>? products,
    List<StockMovement>? movements,
    List<WarehouseOrder>? orders,
    String? searchQuery,
    String? warehouseId,
    String? categoryFilter,
    String? stockFilter,
    InventorySortField? sortField,
    bool? sortAscending,
    int? page,
  }) {
    return InventoryViewState(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      warehouses: warehouses ?? this.warehouses,
      products: products ?? this.products,
      movements: movements ?? this.movements,
      orders: orders ?? this.orders,
      searchQuery: searchQuery ?? this.searchQuery,
      warehouseId: warehouseId ?? this.warehouseId,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      stockFilter: stockFilter ?? this.stockFilter,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      pageSize: pageSize,
    );
  }
}
