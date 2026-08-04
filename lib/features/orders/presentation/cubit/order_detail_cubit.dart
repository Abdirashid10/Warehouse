import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/orders/domain/repositories/orders_repository.dart';

class OrderDetailCubit extends Cubit<ResourceState<WarehouseOrder>> {
  OrderDetailCubit(this._repository) : super(const ResourceState.initial());

  final OrdersRepository _repository;
  String? _orderId;

  Future<void> load(String id) async {
    _orderId = id;
    emit(const ResourceState.loading());
    try {
      final order = await _repository.getOrder(id);
      emit(ResourceState.success(order));
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load order'));
    }
  }

  Future<void> advanceStatus(String nextStatus) async {
    final id = _orderId;
    if (id == null) return;
    emit(ResourceState.loading(data: state.data));
    try {
      final order =
          await _repository.updateOrderStatus(id: id, status: nextStatus);
      emit(ResourceState.success(order));
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: state.data,
      ));
    }
  }
}
