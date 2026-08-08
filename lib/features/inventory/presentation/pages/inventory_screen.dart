import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/presentation/wms_inventory_refresh_bus.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/domain/usecases/get_inventory_usecase.dart';
import 'package:logisticsmobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:logisticsmobile/features/inventory/presentation/widgets/inventory_enterprise_widgets.dart';
import 'package:logisticsmobile/features/inventory/presentation/widgets/inventory_mobile_widgets.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.initialStockFilter});

  /// Pre-select stock filter on load (e.g. `expired` for Expiry & Risk).
  final String? initialStockFilter;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with StaffScopeInitMixin {
  InventoryCubit? _cubit;
  final _searchController = TextEditingController();
  StreamSubscription<void>? _refreshSubscription;

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    final cubit = InventoryCubit(
      GetInventoryUseCase(repositories.inventory),
      repositories.inventory,
      repositories.products,
      repositories.movements,
      repositories.orders,
    );
    _cubit = cubit;
    cubit.load().then((_) {
      final filter = widget.initialStockFilter;
      if (filter != null && filter.isNotEmpty && mounted) {
        cubit.setStockFilter(filter);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshSubscription =
        WmsInventoryRefreshBus.instance.onRefresh.listen((_) {
      _cubit?.refresh();
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _searchController.dispose();
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const StaffScopeLoadingBody();
    }

    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<InventoryCubit, ResourceState<InventoryViewState>>(
        builder: (context, state) {
          if (state.isLoading && state.data == null) {
            return const _InventoryLoadingView();
          }
          if (state.isFailure && state.data == null) {
            return WmsErrorState(
              message: state.message ?? 'Failed to load inventory',
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
                // One page header only. The old layout stacked a page title,
                // three section headers and a separate sort strip above the
                // first product.
                const SliverToBoxAdapter(child: InventoryTrackingHeader()),
                SliverToBoxAdapter(
                  child: InventoryMetricsBar(
                    data: data,
                    onStockFilter: cubit.setStockFilter,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: InventoryMobileUi.blockGap),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: InventoryFilterBar(
                      data: data,
                      searchController: _searchController,
                      onSearch: cubit.setSearch,
                      onWarehouse: cubit.setWarehouse,
                      onCategory: cubit.setCategory,
                      onStockFilter: cubit.setStockFilter,
                      onSort: cubit.setSort,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: InventoryResultsBar(
                      count: data.filtered.length,
                      sortField: data.sortField,
                      sortAscending: data.sortAscending,
                      onSort: cubit.setSort,
                    ),
                  ),
                ),
                if (data.pageItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: WmsEmptyStates.inventory(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= data.pageItems.length) return null;
                          final item = data.pageItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: InventoryProductTile(
                              item: item,
                              lastUpdated: InventoryUi.lastUpdatedFor(
                                item,
                                data.movements,
                              ),
                              availableQuantity: data.availableQuantityFor(item),
                              reservedQuantity: data.reservedQuantityFor(item),
                              onTap: () => _showInventoryDetails(
                                context,
                                data,
                                item,
                              ),
                            ),
                          );
                        },
                        childCount: data.pageItems.length,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _PaginationBar(
                      page: data.page,
                      totalPages: data.totalPages,
                      hasMore: data.hasMore,
                      onPrev: cubit.prevPage,
                      onNext: cubit.nextPage,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    0,
                    AppSpacing.screenPadding,
                    AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: InventoryCriticalAlertsSection(
                      data: data,
                      onItemTap: (item) => _showInventoryDetails(
                        context,
                        data,
                        item,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.hasMore,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final bool hasMore;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: page > 1 ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            'Page $page of $totalPages',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: wms.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          IconButton(
            onPressed: hasMore ? onNext : null,
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

void _showInventoryDetails(
  BuildContext context,
  InventoryViewState data,
  InventoryItem item, {
  int initialTab = 0,
}) {
  final movements = data.movements
      .where((m) => m.sku == item.sku || m.productName == item.productName)
      .toList();
  final orders = data.orders
      .where((o) => o.items.any((line) => line.sku == item.sku))
      .toList();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (context) {
      return DefaultTabController(
        length: 3,
        initialIndex: initialTab.clamp(0, 2),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.86,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text('SKU ${item.sku}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                const TabBar(
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Movements'),
                    Tab(text: 'Orders'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ProductOverviewTab(
                        item: item,
                        category: data.categoryFor(item),
                        lastUpdated:
                            InventoryUi.lastUpdatedFor(item, data.movements),
                        availableQuantity: data.availableQuantityFor(item),
                      ),
                      _ProductMovementsTab(movements: movements),
                      _ProductOrdersTab(orders: orders),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ProductOverviewTab extends StatelessWidget {
  const _ProductOverviewTab({
    required this.item,
    required this.category,
    required this.lastUpdated,
    required this.availableQuantity,
  });

  final InventoryItem item;
  final String category;
  final DateTime? lastUpdated;
  final num availableQuantity;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _SummaryRow('Product', item.productName),
        _SummaryRow('SKU', item.sku),
        _SummaryRow('Barcode', item.sku),
        _SummaryRow('Category', category),
        _SummaryRow('Warehouse', item.warehouseName),
        _SummaryRow('Current Stock', WmsFormatters.quantity(item.quantity)),
        _SummaryRow('Available Stock', WmsFormatters.quantity(availableQuantity)),
        _SummaryRow('Stock Status', InventoryUi.displayStatus(item)),
        _SummaryRow(
          'Reorder Level',
          WmsFormatters.quantity(item.minThreshold ?? 0),
        ),
        _SummaryRow(
          'Last Updated',
          lastUpdated != null
              ? WmsFormatters.relativeTime(lastUpdated)
              : '—',
        ),
      ],
    );
  }
}

class _ProductMovementsTab extends StatelessWidget {
  const _ProductMovementsTab({required this.movements});

  final List<StockMovement> movements;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return const WmsEmptyState(
        title: 'No movements',
        message: 'No stock movements found for this product.',
        icon: Icons.swap_horiz_rounded,
      );
    }
    return ListView.separated(
      itemCount: movements.length,
      separatorBuilder: (_, __) => const Divider(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final m = movements[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(m.type),
          subtitle: Text(
            '${WmsFormatters.quantity(m.quantity)} units · ${m.performedBy}',
          ),
          trailing: Text(WmsFormatters.relativeTime(m.timestamp)),
        );
      },
    );
  }
}

class _ProductOrdersTab extends StatelessWidget {
  const _ProductOrdersTab({required this.orders});

  final List<WarehouseOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const WmsEmptyState(
        title: 'No related orders',
        message: 'Orders containing this product will appear here.',
        icon: Icons.shopping_cart_outlined,
      );
    }
    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, __) => const Divider(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final o = orders[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(o.orderNumber),
          subtitle: Text('${o.customerName} · ${o.status}'),
          trailing: Text(WmsFormatters.currency(o.grandTotal)),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryLoadingView extends StatelessWidget {
  const _InventoryLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        WmsKpiSkeleton(),
        SizedBox(height: AppSpacing.sm),
        WmsSkeletonBox(height: 40, radius: AppSpacing.radiusMd),
        SizedBox(height: AppSpacing.sm),
        WmsSkeletonBox(height: 100, radius: AppSpacing.radiusLg),
      ],
    );
  }
}
