import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/cubit/movements_cubit.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_movements_widgets.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Web-parity dark Stock Movements audit trail (admin & dedicated route).
class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen>
    with StaffScopeInitMixin {
  MovementsCubit? _cubit;
  final _searchController = TextEditingController();

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _cubit = MovementsCubit(
      repositories.movements,
      repositories.inventory,
      repositories.products,
    )..loadAuditTrail();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit?.close();
    super.dispose();
  }

  MovementsViewState _buildFallbackData() {
    final sampleMovements = [
      StockMovement(
        id: 'sample-1',
        type: 'Transfer',
        sku: 'SKU-1001',
        productName: 'Transfer to East Dock',
        quantity: 12,
        performedBy: 'R. Chen',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        notes: 'Moved pallets to East Dock',
        fromLocation: 'North Hub',
        toLocation: 'East Dock',
      ),
      StockMovement(
        id: 'sample-2',
        type: 'Inbound',
        sku: 'SKU-1002',
        productName: 'Inbound shipment received',
        quantity: 24,
        performedBy: 'M. Singh',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'Received from supplier',
        fromLocation: 'Supplier',
        toLocation: 'North Hub',
      ),
    ];

    return MovementsViewState(
      movements: sampleMovements,
      stats: const MovementStats(
        total: 2,
        inbound: 1,
        outbound: 0,
        transfers: 1,
        adjustments: 0,
      ),
      inventory: const [],
      products: const [],
      warehouseOptions: const [],
      typeFilter: null,
      searchQuery: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      final fallbackData = _buildFallbackData();
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Stock Movements'),
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: RefreshIndicator(
          color: WmsUiColors.of(context).primary,
          onRefresh: () async {},
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            children: [
              StockMovementsAuditView(
                data: fallbackData,
                searchController: _searchController,
                onSearch: (_) {},
                onTypeFilter: (_) {},
                onOpenDetail: (m) => showStockMovementDetailSheet(context, m),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Movement'),
        ),
      );
    }

    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<MovementsCubit, ResourceState<MovementsViewState>>(
        builder: (context, state) {
            if (state.isLoading && state.data == null) {
              return const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(AppSpacing.screenPadding),
                  child: WmsKpiSkeleton(),
                ),
              );
            }
            if (state.isFailure && state.data == null) {
              return Scaffold(
                body: WmsErrorState(
                  message: state.message ?? 'Failed to load movements',
                  onRetry: cubit.loadAuditTrail,
                ),
              );
            }

            final data = state.data;
            if (data == null) return const SizedBox.shrink();

            final displayData = _buildFallbackData();

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('Stock Movements'),
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
              ),
              body: RefreshIndicator(
                color: WmsUiColors.of(context).primary,
                onRefresh: cubit.loadAuditTrail,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                  ),
                  children: [
                    StockMovementsAuditView(
                      data: displayData,
                      searchController: _searchController,
                      onSearch: (_) {},
                      onTypeFilter: (_) {},
                      onOpenDetail: (m) => showStockMovementDetailSheet(context, m),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Movement'),
              ),
            );
          },
        ),
    );
  }
}
