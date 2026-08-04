import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/features/warehouses/domain/repositories/warehouses_repository.dart';

class WarehousesListState {
  const WarehousesListState({
    required this.warehouses,
    this.nameQuery = '',
    this.locationQuery = '',
    this.capacityFilter,
    this.showFilters = false,
  });

  final List<Warehouse> warehouses;
  final String nameQuery;
  final String locationQuery;
  final WarehouseCapacityFilter? capacityFilter;
  final bool showFilters;

  WarehousesSummary get summary => WarehousesSummary.fromWarehouses(warehouses);

  WarehousePerformanceRankings get rankings =>
      WarehousePerformanceRankings.fromWarehouses(warehouses);

  int get activeFilterCount => capacityFilter != null ? 1 : 0;

  List<Warehouse> get filtered {
    var list = [...warehouses];

    final name = nameQuery.trim().toLowerCase();
    if (name.isNotEmpty) {
      list = list.where((w) => w.name.toLowerCase().contains(name)).toList();
    }

    final location = locationQuery.trim().toLowerCase();
    if (location.isNotEmpty) {
      list =
          list.where((w) => w.location.toLowerCase().contains(location)).toList();
    }

    if (capacityFilter != null) {
      list = list
          .where((w) => w.matchesCapacityFilter(capacityFilter!))
          .toList();
    }

    return list;
  }

  WarehousesListState copyWith({
    List<Warehouse>? warehouses,
    String? nameQuery,
    String? locationQuery,
    WarehouseCapacityFilter? capacityFilter,
    bool? showFilters,
    bool clearCapacityFilter = false,
  }) {
    return WarehousesListState(
      warehouses: warehouses ?? this.warehouses,
      nameQuery: nameQuery ?? this.nameQuery,
      locationQuery: locationQuery ?? this.locationQuery,
      capacityFilter:
          clearCapacityFilter ? null : (capacityFilter ?? this.capacityFilter),
      showFilters: showFilters ?? this.showFilters,
    );
  }
}

class WarehousesCubit extends Cubit<ResourceState<WarehousesListState>> {
  WarehousesCubit(this._repository) : super(const ResourceState.initial());

  final WarehousesRepository _repository;

  Future<void> load() async {
    final current = state.data;
    emit(ResourceState.loading(data: current));
    try {
      final list = await _repository.getWarehouses();
      final base = (current ?? const WarehousesListState(warehouses: []))
          .copyWith(warehouses: list);
      emit(ResourceState.success(base));
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: current,
      ));
    } catch (_) {
      emit(ResourceState.failure('Failed to load warehouses', data: current));
    }
  }

  void setNameQuery(String query) {
    final data = state.data;
    if (data == null) return;
    emit(ResourceState.success(data.copyWith(nameQuery: query)));
  }

  void setLocationQuery(String query) {
    final data = state.data;
    if (data == null) return;
    emit(ResourceState.success(data.copyWith(locationQuery: query)));
  }

  void setCapacityFilter(WarehouseCapacityFilter? filter) {
    final data = state.data;
    if (data == null) return;
    emit(
      ResourceState.success(
        data.copyWith(
          capacityFilter: filter,
          clearCapacityFilter: filter == null,
        ),
      ),
    );
  }

  void toggleFilters() {
    final data = state.data;
    if (data == null) return;
    emit(ResourceState.success(data.copyWith(showFilters: !data.showFilters)));
  }

  void clearFilters() {
    final data = state.data;
    if (data == null) return;
    emit(
      ResourceState.success(
        data.copyWith(clearCapacityFilter: true),
      ),
    );
  }

  Future<void> create({
    required String name,
    required String location,
    required num capacity,
  }) async {
    try {
      await _repository.createWarehouse(
        name: name,
        location: location,
        capacity: capacity,
      );
      await load();
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: state.data,
      ));
      rethrow;
    }
  }

  Future<void> update({
    required String id,
    String? name,
    String? location,
    num? capacity,
  }) async {
    try {
      await _repository.updateWarehouse(
        id: id,
        name: name,
        location: location,
        capacity: capacity,
      );
      await load();
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: state.data,
      ));
      rethrow;
    }
  }

  Future<void> refresh() => load();
}
