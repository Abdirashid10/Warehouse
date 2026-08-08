import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/domain/usecases/get_notifications_usecase.dart';

enum NotificationCategoryFilter {
  all,
  inventory,
  orders,
  tasks,
  warehouses,
  system,
}

class NotificationsListState {
  const NotificationsListState({
    required this.items,
    required this.unreadCount,
    this.filter = NotificationCategoryFilter.all,
    this.readLocally = const {},
  });

  final List<AppNotification> items;
  final int unreadCount;
  final NotificationCategoryFilter filter;
  final Set<String> readLocally;

  int get effectiveUnreadCount => items.where((n) => !isRead(n)).length;

  bool isRead(AppNotification n) => n.read || readLocally.contains(n.id);

  List<AppNotification> get filtered {
    return items.where((n) => matchesCategory(n, filter)).toList();
  }

  List<AppNotification> get inventoryItems => items
      .where((n) => matchesCategory(n, NotificationCategoryFilter.inventory))
      .toList();

  List<AppNotification> get orderItems => items
      .where((n) => matchesCategory(n, NotificationCategoryFilter.orders))
      .toList();

  List<AppNotification> get taskItems => items
      .where((n) => matchesCategory(n, NotificationCategoryFilter.tasks))
      .toList();

  List<AppNotification> get warehouseItems => items
      .where((n) => matchesCategory(n, NotificationCategoryFilter.warehouses))
      .toList();

  List<AppNotification> get systemItems => items
      .where((n) => matchesCategory(n, NotificationCategoryFilter.system))
      .toList();

  int unreadFor(NotificationCategoryFilter category) =>
      items.where((n) => matchesCategory(n, category) && !isRead(n)).length;

  static bool matchesCategory(
    AppNotification n,
    NotificationCategoryFilter filter,
  ) {
    final text = '${n.title} ${n.message} ${n.type}'.toLowerCase();
    switch (filter) {
      case NotificationCategoryFilter.all:
        return true;
      case NotificationCategoryFilter.inventory:
        return text.contains('inventory') ||
            text.contains('stock') ||
            text.contains('low stock');
      case NotificationCategoryFilter.orders:
        return text.contains('order');
      case NotificationCategoryFilter.tasks:
        return text.contains('task');
      case NotificationCategoryFilter.warehouses:
        return text.contains('warehouse') ||
            text.contains('location') ||
            text.contains('capacity');
      case NotificationCategoryFilter.system:
        return !text.contains('inventory') &&
            !text.contains('stock') &&
            !text.contains('order') &&
            !text.contains('task') &&
            !text.contains('warehouse') &&
            !text.contains('location') &&
            !text.contains('capacity');
    }
  }

  NotificationsListState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    NotificationCategoryFilter? filter,
    Set<String>? readLocally,
  }) {
    return NotificationsListState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      filter: filter ?? this.filter,
      readLocally: readLocally ?? this.readLocally,
    );
  }
}

class NotificationsCubit extends Cubit<ResourceState<NotificationsListState>> {
  NotificationsCubit(this._getNotifications) : super(const ResourceState.initial());

  final GetNotificationsUseCase _getNotifications;

  Future<void> load() async {
    emit(const ResourceState.loading());
    try {
      final result = await _getNotifications();
      emit(
        ResourceState.success(
          NotificationsListState(
            items: result.items,
            unreadCount: result.unreadCount,
          ),
        ),
      );
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load notifications'));
    }
  }

  void setFilter(NotificationCategoryFilter filter) {
    final data = state.data;
    if (data == null) return;
    emit(ResourceState.success(data.copyWith(filter: filter)));
  }

  void markAsRead(AppNotification notification) {
    final data = state.data;
    if (data == null || data.isRead(notification)) return;
    final updated = {...data.readLocally, notification.id};
    emit(ResourceState.success(data.copyWith(readLocally: updated)));
  }

  void markAllRead() {
    final data = state.data;
    if (data == null) return;
    final updated = data.items.map((n) => n.id).toSet();
    emit(ResourceState.success(data.copyWith(readLocally: updated)));
  }

  Future<void> refresh() => load();
}
