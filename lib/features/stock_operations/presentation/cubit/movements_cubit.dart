import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/presentation/wms_inventory_refresh_bus.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/repositories/products_repository.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/create_movement_input.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/stock_operations/domain/repositories/movements_repository.dart';

class MovementsViewState {
  const MovementsViewState({
    required this.movements,
    required this.stats,
    required this.inventory,
    required this.products,
    required this.warehouseOptions,
    this.typeFilter,
    this.searchQuery = '',
  });

  final List<StockMovement> movements;
  final MovementStats stats;
  final List<InventoryItem> inventory;
  final List<Product> products;
  final List<WarehouseOption> warehouseOptions;
  final String? typeFilter;
  final String searchQuery;

  List<String> get warehouses {
    if (warehouseOptions.isNotEmpty) {
      return warehouseOptions.map((w) => w.name).toList()..sort();
    }
    return inventory
        .map((i) => i.warehouseName)
        .toSet()
        .where((w) => w.isNotEmpty)
        .toList()
      ..sort();
  }

  WarehouseOption? warehouseById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final w in warehouseOptions) {
      if (w.id == id) return w;
    }
    return null;
  }

  WarehouseOption? warehouseByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final w in warehouseOptions) {
      if (w.name == name) return w;
    }
    return null;
  }

  List<WarehouseOption> get resolvedWarehouses {
    if (warehouseOptions.isNotEmpty) {
      return [...warehouseOptions]..sort((a, b) => a.name.compareTo(b.name));
    }
    final byId = <String, WarehouseOption>{};
    for (final item in inventory) {
      final id = item.warehouseId;
      if (id == null || id.isEmpty) continue;
      byId[id] = WarehouseOption(id: id, name: item.warehouseName);
    }
    return byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Product> get catalog => products..sort((a, b) => a.name.compareTo(b.name));

  num availableQuantity({
    required String sku,
    String? warehouseId,
    String? warehouseName,
  }) {
    return inventory.where((i) {
      if (i.sku != sku) return false;
      if (warehouseId != null && warehouseId.isNotEmpty) {
        return i.warehouseId == warehouseId;
      }
      if (warehouseName != null && warehouseName.isNotEmpty) {
        return i.warehouseName == warehouseName;
      }
      return false;
    }).fold<num>(0, (sum, item) => sum + item.quantity);
  }

  List<StockMovement> get filtered {
    return movements.where((m) {
      if (typeFilter != null && typeFilter!.isNotEmpty) {
        if (_norm(m.type) != _norm(typeFilter!)) return false;
      }
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return m.productName.toLowerCase().contains(q) ||
          m.sku.toLowerCase().contains(q) ||
          m.performedBy.toLowerCase().contains(q) ||
          (m.fromLocation ?? '').toLowerCase().contains(q) ||
          (m.toLocation ?? '').toLowerCase().contains(q) ||
          m.type.toLowerCase().contains(q) ||
          (m.notes ?? '').toLowerCase().contains(q);
    }).toList();
  }

  static String _norm(String value) => value.toUpperCase().trim();

  int get todaysInbound => _countTodayByType('INBOUND');
  int get todaysOutbound => _countTodayByType('OUTBOUND');
  int get todaysTransfers => _countTodayByType('TRANSFER');
  int get todaysReturns => _countTodayByType('RETURN');

  int _countTodayByType(String type) {
    final now = DateTime.now();
    final target = type.toUpperCase();
    return movements.where((m) {
      final ts = m.timestamp;
      if (ts == null || MovementsViewState._norm(m.type) != target) return false;
      return ts.year == now.year && ts.month == now.month && ts.day == now.day;
    }).length;
  }
}

class MovementsCubit extends Cubit<ResourceState<MovementsViewState>> {
  MovementsCubit(
    this._repository,
    this._inventoryRepository,
    this._productsRepository,
  ) : super(const ResourceState.initial());

  final MovementsRepository _repository;
  final InventoryRepository _inventoryRepository;
  final ProductsRepository _productsRepository;

  Future<void> load({String? type}) async {
    emit(const ResourceState.loading());
    try {
      final results = await Future.wait([
        _repository.getMovements(type: type),
        _inventoryRepository.getTracking(),
        _productsRepository.getProducts(),
        _inventoryRepository.getWarehouses(),
      ]);
      final result =
          results[0] as ({List<StockMovement> movements, MovementStats stats});
      final inventory =
          (results[1]
                  as ({List<InventoryItem> items, InventorySummary summary}))
              .items;
      final products = results[2] as List<Product>;
      final warehouseOptions = results[3] as List<WarehouseOption>;
      emit(
        ResourceState.success(
          MovementsViewState(
            movements: result.movements,
            stats: result.stats,
            inventory: inventory,
            products: products,
            warehouseOptions: warehouseOptions,
            typeFilter: type,
          ),
        ),
      );
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load movements'));
    }
  }

  Future<StockMovement> submitMovement(CreateMovementInput input) async {
    try {
      final movement = await _repository.createMovement(input);
      await refresh();
      WmsInventoryRefreshBus.instance.notifyInventoryChanged();
      return movement;
    } on ApiException {
      rethrow;
    }
  }

  void setSearch(String query) {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.success(current.copyWith(searchQuery: query)));
  }

  void setTypeFilter(String? type) {
    final current = state.data;
    if (current == null) return;
    emit(ResourceState.success(current.copyWith(typeFilter: type)));
  }

  Future<void> loadAuditTrail({String? type}) async {
    emit(ResourceState.loading(data: state.data));
    try {
      final result = await _repository.getMovements(type: type);
      final current = state.data;
      emit(
        ResourceState.success(
          MovementsViewState(
            movements: result.movements,
            stats: result.stats,
            inventory: current?.inventory ?? const [],
            products: current?.products ?? const [],
            warehouseOptions: current?.warehouseOptions ?? const [],
            typeFilter: type ?? current?.typeFilter,
            searchQuery: current?.searchQuery ?? '',
          ),
        ),
      );
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: state.data,
      ));
    } catch (_) {
      emit(ResourceState.failure(
        'Failed to load movements',
        data: state.data,
      ));
    }
  }

  Future<void> refresh() => load(type: state.data?.typeFilter);
}

extension on MovementsViewState {
  MovementsViewState copyWith({
    List<StockMovement>? movements,
    MovementStats? stats,
    List<InventoryItem>? inventory,
    List<Product>? products,
    List<WarehouseOption>? warehouseOptions,
    String? typeFilter,
    String? searchQuery,
  }) {
    return MovementsViewState(
      movements: movements ?? this.movements,
      stats: stats ?? this.stats,
      inventory: inventory ?? this.inventory,
      products: products ?? this.products,
      warehouseOptions: warehouseOptions ?? this.warehouseOptions,
      typeFilter: typeFilter ?? this.typeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
