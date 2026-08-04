import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/auth/domain/entities/user_role.dart';
import 'package:logisticsmobile/features/users/domain/entities/create_user_input.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/users/domain/repositories/users_repository.dart';

enum UserStatusFilter { all, active, inactive }

/// Fixed role chips for enterprise user management filters.
abstract final class UserRoleFilters {
  static const admin = 'Admin';
  static const supervisor = 'Supervisor';
  static const staff = 'Staff';

  static const chips = [admin, supervisor, staff];

  static bool matches(WmsUser user, String filter) {
    final role = UserRole.fromString(user.role);
    switch (filter) {
      case admin:
        return role == UserRole.admin;
      case supervisor:
        return role == UserRole.supervisor;
      case staff:
        return role == UserRole.staff || role == UserRole.unknown;
      default:
        return user.role == filter;
    }
  }
}

class UsersListState {
  const UsersListState({
    required this.allUsers,
    this.searchQuery = '',
    this.roleFilter,
    this.warehouseFilter,
    this.statusFilter = UserStatusFilter.all,
    this.page = 1,
    this.pageSize = 20,
  });

  final List<WmsUser> allUsers;
  final String searchQuery;
  final String? roleFilter;
  final String? warehouseFilter;
  final UserStatusFilter statusFilter;
  final int page;
  final int pageSize;

  List<String> get warehouses {
    final set = <String>{};
    for (final u in allUsers) {
      final w = u.assignedWarehouse;
      if (w != null && w.isNotEmpty) set.add(w);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<WmsUser> get filtered {
    var list = allUsers.where((u) => !u.archived);
    if (roleFilter != null && roleFilter!.isNotEmpty) {
      list = list.where((u) => UserRoleFilters.matches(u, roleFilter!));
    }
    if (warehouseFilter != null && warehouseFilter!.isNotEmpty) {
      list = list.where((u) => u.assignedWarehouse == warehouseFilter);
    }
    switch (statusFilter) {
      case UserStatusFilter.active:
        list = list.where((u) => u.isActive);
      case UserStatusFilter.inactive:
        list = list.where((u) => !u.isActive);
      case UserStatusFilter.all:
        break;
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where(
        (u) =>
            u.displayName.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.role.toLowerCase().contains(q) ||
            (u.assignedWarehouse?.toLowerCase().contains(q) ?? false),
      );
    }
    return list.toList();
  }

  List<WmsUser> get pageItems {
    final f = filtered;
    final start = (page - 1) * pageSize;
    if (start >= f.length) return [];
    final end = (start + pageSize).clamp(0, f.length);
    return f.sublist(start, end);
  }

  int get totalPages {
    final n = filtered.length;
    if (n == 0) return 1;
    return (n / pageSize).ceil();
  }

  bool get hasMore => page < totalPages;

  UsersListState copyWith({
    List<WmsUser>? allUsers,
    String? searchQuery,
    String? roleFilter,
    String? warehouseFilter,
    UserStatusFilter? statusFilter,
    int? page,
    bool clearRoleFilter = false,
    bool clearWarehouseFilter = false,
  }) {
    return UsersListState(
      allUsers: allUsers ?? this.allUsers,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      warehouseFilter:
          clearWarehouseFilter ? null : (warehouseFilter ?? this.warehouseFilter),
      statusFilter: statusFilter ?? this.statusFilter,
      page: page ?? this.page,
      pageSize: pageSize,
    );
  }
}

class UsersCubit extends Cubit<ResourceState<UsersListState>> {
  UsersCubit(this._repository) : super(const ResourceState.initial());

  final UsersRepository _repository;

  Future<void> load() async {
    emit(const ResourceState.loading());
    try {
      final users = await _repository.getUsers();
      emit(ResourceState.success(UsersListState(allUsers: users)));
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load users'));
    }
  }

  void setSearch(String query) {
    final data = state.data;
    if (data == null) return;
    emit(ResourceState.success(data.copyWith(searchQuery: query, page: 1)));
  }

  void setRoleFilter(String? role) {
    final data = state.data;
    if (data == null) return;
    emit(
      ResourceState.success(
        data.copyWith(
          roleFilter: role,
          page: 1,
          clearRoleFilter: role == null,
        ),
      ),
    );
  }

  void setWarehouseFilter(String? warehouse) {
    final data = state.data;
    if (data == null) return;
    emit(
      ResourceState.success(
        data.copyWith(
          warehouseFilter: warehouse,
          page: 1,
          clearWarehouseFilter: warehouse == null,
        ),
      ),
    );
  }

  void setStatusFilter(UserStatusFilter filter) {
    final data = state.data;
    if (data == null) return;
    emit(ResourceState.success(data.copyWith(statusFilter: filter, page: 1)));
  }

  void nextPage() {
    final data = state.data;
    if (data == null || !data.hasMore) return;
    emit(ResourceState.success(data.copyWith(page: data.page + 1)));
  }

  void prevPage() {
    final data = state.data;
    if (data == null || data.page <= 1) return;
    emit(ResourceState.success(data.copyWith(page: data.page - 1)));
  }

  Future<WmsUser> createUser(CreateUserInput input) async {
    try {
      final created = await _repository.createUser(input);
      final data = state.data;
      if (data != null) {
        emit(
          ResourceState.success(
            data.copyWith(allUsers: [...data.allUsers, created]),
          ),
        );
      }
      return created;
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e), data: state.data));
      rethrow;
    }
  }

  Future<void> updateStatus(WmsUser user, String status) async {
    try {
      final updated = await _repository.updateUserStatus(id: user.id, status: status);
      final data = state.data;
      if (data == null) return;
      final list = data.allUsers.map((u) => u.id == updated.id ? updated : u).toList();
      emit(ResourceState.success(data.copyWith(allUsers: list)));
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e), data: state.data));
    }
  }

  Future<void> refresh() => load();
}
