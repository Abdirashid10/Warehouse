import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/audit/domain/repositories/audit_repository.dart';

class AuditListState {
  const AuditListState({
    required this.activities,
    required this.page,
    required this.pages,
    required this.total,
    this.searchQuery = '',
    this.moduleFilter,
    this.isLoadingMore = false,
  });

  final List<AuditActivity> activities;
  final int page;
  final int pages;
  final int total;
  final String searchQuery;
  final String? moduleFilter;
  final bool isLoadingMore;

  bool get hasMore => page < pages;

  AuditListState copyWith({
    List<AuditActivity>? activities,
    int? page,
    int? pages,
    int? total,
    String? searchQuery,
    String? moduleFilter,
    bool? isLoadingMore,
    bool clearModule = false,
  }) {
    return AuditListState(
      activities: activities ?? this.activities,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
      moduleFilter: clearModule ? null : (moduleFilter ?? this.moduleFilter),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class AuditCubit extends Cubit<ResourceState<AuditListState>> {
  AuditCubit(this._repository) : super(const ResourceState.initial());

  final AuditRepository _repository;

  Future<void> load({String? query, String? module}) async {
    emit(const ResourceState.loading());
    try {
      final page = await _repository.getActivities(
        page: 1,
        query: query,
        module: module,
      );
      emit(
        ResourceState.success(
          AuditListState(
            activities: page.activities,
            page: page.page,
            pages: page.pages,
            total: page.total,
            searchQuery: query ?? '',
            moduleFilter: module,
          ),
        ),
      );
    } on ApiException catch (e) {
      emit(ResourceState.failure(ErrorMessageMapper.fromApiException(e)));
    } catch (_) {
      emit(const ResourceState.failure('Failed to load audit logs'));
    }
  }

  Future<void> loadMore() async {
    final data = state.data;
    if (data == null || !data.hasMore || data.isLoadingMore) return;
    emit(ResourceState.success(data.copyWith(isLoadingMore: true)));
    try {
      final next = await _repository.getActivities(
        page: data.page + 1,
        query: data.searchQuery.isEmpty ? null : data.searchQuery,
        module: data.moduleFilter,
      );
      emit(
        ResourceState.success(
          data.copyWith(
            activities: [...data.activities, ...next.activities],
            page: next.page,
            pages: next.pages,
            total: next.total,
            isLoadingMore: false,
          ),
        ),
      );
    } on ApiException catch (e) {
      emit(
        ResourceState.failure(
          ErrorMessageMapper.fromApiException(e),
          data: data.copyWith(isLoadingMore: false),
        ),
      );
    }
  }

  Future<void> refresh() => load(
        query: state.data?.searchQuery,
        module: state.data?.moduleFilter,
      );
}
