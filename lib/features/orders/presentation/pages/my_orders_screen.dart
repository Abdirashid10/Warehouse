import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:logisticsmobile/features/orders/presentation/widgets/orders_enterprise_widgets.dart';
import 'package:logisticsmobile/routes/wms_route_paths.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Mobile-first orders page — web structure: header, KPIs, search, order cards.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with StaffScopeInitMixin {
  OrdersCubit? _cubit;
  final _searchController = TextEditingController();

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _cubit = OrdersCubit(
      repositories.orders,
      repositories.inventory,
      repositories.products,
      repositories.notifications,
    )..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit?.close();
    super.dispose();
  }

  void _applyStatusFilter(String? status) {
    _cubit?.setStatusFilter(status);
    _cubit?.load(status: status);
  }

  void _openOrderDetail(BuildContext context, String orderId) {
    context.push(WmsRoutePaths.orderDetail(context, orderId));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) return const StaffScopeLoadingBody();

    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<OrdersCubit, ResourceState<OrdersViewState>>(
        builder: (context, state) {
          if (state.isLoading && state.data == null) {
            return const _OrdersLoadingView();
          }
          if (state.isFailure && state.data == null) {
            return WmsErrorState(
              message: state.message ?? 'Failed to load orders',
              onRetry: cubit.refresh,
            );
          }
          final data = state.data;
          if (data == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: OrdersMobileHeader(
                    onNewOrder: () => showCreateOrderSheet(context, data: data),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MobileUi.dashboardSectionGap),
                ),
                SliverToBoxAdapter(
                  child: OrdersMobileKpiGrid(
                    data: data,
                    onStatusTap: _applyStatusFilter,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MobileUi.dashboardSectionGap),
                ),
                SliverToBoxAdapter(
                  child: OrdersMobileSearchSection(
                    data: data,
                    searchController: _searchController,
                    onSearch: cubit.setSearch,
                    onStatusFilter: _applyStatusFilter,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MobileUi.dashboardSectionGap),
                ),
                if (data.filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: WmsEmptyStates.orders(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= data.filtered.length) return null;
                          final order = data.filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: OrdersMobileCard(
                              order: order,
                              warehouse: data.inferredWarehouse(order),
                              onTap: () => _openOrderDetail(context, order.id),
                            ),
                          );
                        },
                        childCount: data.filtered.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxxl),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrdersLoadingView extends StatelessWidget {
  const _OrdersLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        WmsSkeletonBox(height: 120, radius: AppSpacing.radiusLg),
        SizedBox(height: AppSpacing.md),
        WmsKpiSkeleton(),
        SizedBox(height: AppSpacing.md),
        WmsSkeletonBox(height: 48, radius: AppSpacing.radiusMd),
        SizedBox(height: AppSpacing.md),
        WmsSkeletonBox(height: 180, radius: AppSpacing.radiusLg),
      ],
    );
  }
}
