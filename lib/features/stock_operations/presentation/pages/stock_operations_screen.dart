import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/create_movement_input.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/cubit/movements_cubit.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/utils/movement_form_utils.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_kpi_strip.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_movements_widgets.dart';

class StockOperationsScreen extends StatefulWidget {
  const StockOperationsScreen({
    super.key,
    this.title = 'Stock Operations',
    this.initialTab = 0,
  });

  final String title;
  final int initialTab;

  @override
  State<StockOperationsScreen> createState() => _StockOperationsScreenState();
}

class _StockOperationsScreenState extends State<StockOperationsScreen>
    with StaffScopeInitMixin {
  MovementsCubit? _cubit;
  final _searchController = TextEditingController();

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    _cubit = MovementsCubit(
      repositories.movements,
      repositories.inventory,
      repositories.products,
    )..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    final colors = WmsUiColors.of(context);
    if (cubit == null) {
      return const Scaffold(body: StaffScopeLoadingBody());
    }

    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<MovementsCubit, ResourceState<MovementsViewState>>(
        builder: (context, state) {
          if (state.isLoading && state.data == null) {
            return const _StockOpsLoadingView();
          }
          if (state.isFailure && state.data == null) {
            return WmsErrorState(
              message: state.message ?? 'Failed to load stock operations',
              onRetry: cubit.refresh,
            );
          }

          final data = state.data;
          if (data == null) return const SizedBox.shrink();

          return DefaultTabController(
            length: 6,
            initialIndex: widget.initialTab.clamp(0, 5),
            child: Scaffold(
              appBar: AppBar(title: Text(widget.title)),
              body: RefreshIndicator(
                onRefresh: cubit.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _StockOpsHeader(data: data, title: widget.title),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StockOpsTabDelegate(
                        child: Container(
                          color: colors.background,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                            vertical: AppSpacing.sm,
                          ),
                          child: const TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            tabs: [
                              Tab(text: 'Receive'),
                              Tab(text: 'Dispatch'),
                              Tab(text: 'Transfer'),
                              Tab(text: 'Return'),
                              Tab(text: 'History'),
                              Tab(text: 'Alerts'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        child: TabBarView(
                          children: [
                            _MovementFormTab(
                              title: 'Receive Stock (Inbound)',
                              type: WmsMovementTypes.inbound,
                              data: data,
                              requiresDestination: false,
                            ),
                            _MovementFormTab(
                              title: 'Dispatch Stock (Outbound)',
                              type: WmsMovementTypes.outbound,
                              data: data,
                              requiresDestination: true,
                              enforceAvailable: true,
                            ),
                            _MovementFormTab(
                              title: 'Stock Transfer',
                              type: WmsMovementTypes.transfer,
                              data: data,
                              requiresSourceAndDestination: true,
                              enforceAvailable: true,
                            ),
                            _ReturnFormTab(data: data),
                            _MovementHistoryTab(
                              data: data,
                              searchController: _searchController,
                              onSearch: cubit.setSearch,
                              onTypeFilter: cubit.setTypeFilter,
                              cubit: cubit,
                              onOpenDetail: (movement) =>
                                  showStockMovementDetailSheet(context, movement),
                            ),
                            _StockAlertsTab(data: data),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StockOpsHeader extends StatelessWidget {
  const _StockOpsHeader({required this.data, required this.title});

  final MovementsViewState data;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusXl),
          bottomRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Inbound, outbound, transfer, and return workflows',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          WmsKpiStrip(
            items: [
              WmsKpiItem(
                label: "Today's Inbound",
                value: '${data.todaysInbound}',
                icon: Icons.download_rounded,
                color: AppColors.success,
                background: Colors.white,
              ),
              WmsKpiItem(
                label: "Today's Outbound",
                value: '${data.todaysOutbound}',
                icon: Icons.upload_rounded,
                color: const Color(0xFFC2410C),
                background: Colors.white,
              ),
              WmsKpiItem(
                label: "Today's Transfers",
                value: '${data.todaysTransfers}',
                icon: Icons.swap_horiz_rounded,
                color: AppColors.info,
                background: Colors.white,
              ),
              WmsKpiItem(
                label: "Today's Returns",
                value: '${data.todaysReturns}',
                icon: Icons.undo_rounded,
                color: AppColors.accent,
                background: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovementFormTab extends StatefulWidget {
  const _MovementFormTab({
    required this.title,
    required this.type,
    required this.data,
    this.requiresDestination = false,
    this.requiresSourceAndDestination = false,
    this.enforceAvailable = false,
  });

  final String title;
  final String type;
  final MovementsViewState data;
  final bool requiresDestination;
  final bool requiresSourceAndDestination;
  final bool enforceAvailable;

  @override
  State<_MovementFormTab> createState() => _MovementFormTabState();
}

class _MovementFormTabState extends State<_MovementFormTab> {
  WarehouseOption? _warehouse;
  WarehouseOption? _sourceWarehouse;
  WarehouseOption? _destinationWarehouse;
  Product? _product;
  var _submitting = false;
  final _qtyCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _batchCtrl.dispose();
    _supplierCtrl.dispose();
    _referenceCtrl.dispose();
    _destinationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warehouses = widget.data.resolvedWarehouses;
    final products = widget.data.catalog;
    final selectedWarehouse = widget.requiresSourceAndDestination
        ? _sourceWarehouse
        : _warehouse;
    final available = (_product != null && selectedWarehouse != null)
        ? widget.data.availableQuantity(
            sku: _product!.sku,
            warehouseId: selectedWarehouse.id,
            warehouseName: selectedWarehouse.name,
          )
        : 0;

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!widget.requiresSourceAndDestination)
          _DropdownField<WarehouseOption>(
            label: 'Warehouse',
            value: _warehouse,
            items: warehouses,
            getLabel: (w) => w.name,
            onChanged: (v) => setState(() => _warehouse = v),
          ),
        if (widget.requiresSourceAndDestination) ...[
          _DropdownField<WarehouseOption>(
            label: 'Source Warehouse',
            value: _sourceWarehouse,
            items: warehouses,
            getLabel: (w) => w.name,
            onChanged: (v) => setState(() => _sourceWarehouse = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DropdownField<WarehouseOption>(
            label: 'Destination Warehouse',
            value: _destinationWarehouse,
            items: warehouses,
            getLabel: (w) => w.name,
            onChanged: (v) => setState(() => _destinationWarehouse = v),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        _DropdownField<Product>(
          label: 'Product',
          value: _product,
          items: products,
          getLabel: (p) => '${p.name} · ${p.sku}',
          onChanged: (v) => setState(() => _product = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _batchCtrl,
          decoration: const InputDecoration(labelText: 'Batch Number'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _supplierCtrl,
          decoration: const InputDecoration(labelText: 'Supplier'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _referenceCtrl,
          decoration: const InputDecoration(labelText: 'Reference Number'),
        ),
        if (widget.requiresDestination) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _destinationCtrl,
            decoration: const InputDecoration(labelText: 'Destination'),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SummaryRow('Available Stock', WmsFormatters.quantity(available)),
              _SummaryRow('Reorder Level', 'Live from inventory thresholds'),
              _SummaryRow('Warehouse', selectedWarehouse?.name ?? 'Select warehouse'),
            ],
          ),
        ),
        if (widget.enforceAvailable) ...[
          const SizedBox(height: AppSpacing.sm),
          Builder(
            builder: (context) {
              final qty = num.tryParse(_qtyCtrl.text.trim()) ?? 0;
              final invalid = qty > available;
              return Text(
                invalid
                    ? 'Cannot dispatch/transfer more than available quantity.'
                    : 'Current available quantity: ${WmsFormatters.quantity(available)}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: invalid
                          ? AppColors.error
                          : WmsUiColors.of(context).textSecondary,
                      fontWeight: invalid ? FontWeight.w700 : FontWeight.w500,
                    ),
              );
            },
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: _submitting ? null : () => _submit(context),
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Text(_submitting ? 'Submitting…' : 'Submit Operation'),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<MovementsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    if (_product == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select a product.')),
      );
      return;
    }

    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a quantity greater than zero.')),
      );
      return;
    }

    final notes = _notesCtrl.text.trim();
    final supplier = _supplierCtrl.text.trim();
    final reference = _referenceCtrl.text.trim();
    final reason = buildMovementReason(
      notes: notes,
      supplier: supplier,
      referenceNumber: reference,
    );
    final reasonError = validateMovementReason(reason);
    if (reasonError != null) {
      messenger.showSnackBar(SnackBar(content: Text(reasonError)));
      return;
    }

    WarehouseOption? warehouse = _warehouse;
    WarehouseOption? fromWarehouse = _sourceWarehouse;
    WarehouseOption? toWarehouse = _destinationWarehouse;

    if (widget.requiresSourceAndDestination) {
      if (fromWarehouse == null || toWarehouse == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Select source and destination warehouses.')),
        );
        return;
      }
      if (fromWarehouse.id == toWarehouse.id) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Source and destination must be different.'),
          ),
        );
        return;
      }
    } else if (warehouse == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select a warehouse.')),
      );
      return;
    }

    if (widget.enforceAvailable && qty > availableQuantityForSelection()) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Quantity exceeds available stock.')),
      );
      return;
    }

    if (widget.type == WmsMovementTypes.outbound) {
      final destination = _destinationCtrl.text.trim();
      if (destination.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Destination is required for dispatch.')),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      late final CreateMovementInput input;
      switch (widget.type) {
        case WmsMovementTypes.inbound:
          input = CreateMovementInput(
            type: WmsMovementTypes.inbound,
            productId: _product!.id,
            warehouseId: warehouse!.id,
            quantity: qty,
            reason: reason,
            batchNumber: _batchCtrl.text.trim(),
            sourceLocation: supplier.isNotEmpty ? supplier : null,
          );
        case WmsMovementTypes.outbound:
          input = CreateMovementInput(
            type: WmsMovementTypes.outbound,
            productId: _product!.id,
            warehouseId: warehouse!.id,
            quantity: qty,
            reason: reason,
            customerName: _destinationCtrl.text.trim(),
          );
        case WmsMovementTypes.transfer:
          input = CreateMovementInput(
            type: WmsMovementTypes.transfer,
            productId: _product!.id,
            fromWarehouseId: fromWarehouse!.id,
            toWarehouseId: toWarehouse!.id,
            quantity: qty,
            reason: reason,
            sourceLocation: fromWarehouse.name,
            destinationLocation: toWarehouse.name,
          );
        default:
          input = CreateMovementInput(
            type: widget.type,
            productId: _product!.id,
            warehouseId: warehouse!.id,
            quantity: qty,
            reason: reason,
          );
      }

      await cubit.submitMovement(input);

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(_successMessage(widget.type)),
          backgroundColor: AppColors.success,
        ),
      );
      _clearForm();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.fromApiException(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not complete the operation. Check your connection.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  num availableQuantityForSelection() {
    final selected = widget.requiresSourceAndDestination
        ? _sourceWarehouse
        : _warehouse;
    if (_product == null || selected == null) return 0;
    return widget.data.availableQuantity(
      sku: _product!.sku,
      warehouseId: selected.id,
      warehouseName: selected.name,
    );
  }

  void _clearForm() {
    _qtyCtrl.clear();
    _batchCtrl.clear();
    _supplierCtrl.clear();
    _referenceCtrl.clear();
    _destinationCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _product = null;
      if (!widget.requiresSourceAndDestination) {
        _warehouse = null;
      } else {
        _sourceWarehouse = null;
        _destinationWarehouse = null;
      }
    });
  }

  String _successMessage(String type) {
    switch (type) {
      case WmsMovementTypes.inbound:
        return 'Inventory received successfully.';
      case WmsMovementTypes.outbound:
        return 'Stock dispatched successfully.';
      case WmsMovementTypes.transfer:
        return 'Stock transferred successfully.';
      default:
        return 'Operation completed successfully.';
    }
  }
}

class _ReturnFormTab extends StatefulWidget {
  const _ReturnFormTab({required this.data});

  final MovementsViewState data;

  @override
  State<_ReturnFormTab> createState() => _ReturnFormTabState();
}

class _ReturnFormTabState extends State<_ReturnFormTab> {
  Product? _product;
  WarehouseOption? _warehouse;
  var _submitting = false;
  final _qtyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final warehouses = widget.data.resolvedWarehouses;
    final available = (_product != null && _warehouse != null)
        ? widget.data.availableQuantity(
            sku: _product!.sku,
            warehouseId: _warehouse!.id,
            warehouseName: _warehouse!.name,
          )
        : 0;

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
      children: [
        Text(
          'Return Stock',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DropdownField<WarehouseOption>(
          label: 'Warehouse',
          value: _warehouse,
          items: warehouses,
          getLabel: (w) => w.name,
          onChanged: (v) => setState(() => _warehouse = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DropdownField<Product>(
          label: 'Product',
          value: _product,
          items: widget.data.catalog,
          getLabel: (p) => '${p.name} · ${p.sku}',
          onChanged: (v) => setState(() => _product = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _reasonCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Return Reason'),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: _SummaryRow(
            'Current available quantity',
            WmsFormatters.quantity(available),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: _submitting ? null : () => _submitReturn(context),
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.undo_rounded),
          label: Text(_submitting ? 'Submitting…' : 'Submit Return'),
        ),
      ],
    );
  }

  Future<void> _submitReturn(BuildContext context) async {
    final cubit = context.read<MovementsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    if (_product == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Select a product.')));
      return;
    }
    if (_warehouse == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Select a warehouse.')));
      return;
    }

    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a quantity greater than zero.')),
      );
      return;
    }

    final reason = buildMovementReason(notes: _reasonCtrl.text.trim());
    final reasonError = validateMovementReason(reason);
    if (reasonError != null) {
      messenger.showSnackBar(SnackBar(content: Text(reasonError)));
      return;
    }

    setState(() => _submitting = true);
    try {
      await cubit.submitMovement(
        CreateMovementInput(
          type: WmsMovementTypes.returnType,
          productId: _product!.id,
          warehouseId: _warehouse!.id,
          quantity: qty,
          reason: reason,
          sourceLocation: 'Customer Return',
          destinationLocation: _warehouse!.name,
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Return recorded successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      _qtyCtrl.clear();
      _reasonCtrl.clear();
      setState(() {
        _product = null;
        _warehouse = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.fromApiException(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not record return. Check your connection.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _MovementHistoryTab extends StatelessWidget {
  const _MovementHistoryTab({
    required this.data,
    required this.searchController,
    required this.onSearch,
    required this.onTypeFilter,
    required this.onOpenDetail,
    required this.cubit,
  });

  final MovementsViewState data;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onTypeFilter;
  final ValueChanged<StockMovement> onOpenDetail;
  final MovementsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            StockMovementsAuditView(
              embedded: true,
              data: data,
              searchController: searchController,
              onSearch: onSearch,
              onTypeFilter: (type) {
                onTypeFilter(type);
                cubit.loadAuditTrail(type: type);
              },
              onOpenDetail: onOpenDetail,
            ),
          ],
        );
  }
}

class _StockAlertsTab extends StatelessWidget {
  const _StockAlertsTab({required this.data});

  final MovementsViewState data;

  @override
  Widget build(BuildContext context) {
    final low = data.inventory.where((i) => i.stockStatus == WmsStockStatuses.lowStock).toList();
    final out = data.inventory.where((i) => i.stockStatus == WmsStockStatuses.outOfStock).toList();
    final transferFailures = data.movements
        .where((m) =>
            m.type == WmsMovementTypes.transfer &&
            (m.notes ?? '').toLowerCase().contains('fail'))
        .toList();

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
      children: [
        if (low.isEmpty && out.isEmpty && transferFailures.isEmpty)
          const WmsEmptyState(
            title: 'No active alerts',
            message: 'Low stock, out-of-stock, and transfer-failure alerts appear here.',
            icon: Icons.verified_outlined,
          )
        else ...[
          if (low.isNotEmpty)
            _AlertCard(
              title: 'Low Stock',
              color: AppColors.warning,
              lines: low.map((i) => '${i.productName} · ${i.warehouseName}').toList(),
            ),
          if (low.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          if (out.isNotEmpty)
            _AlertCard(
              title: 'Out Of Stock',
              color: AppColors.error,
              lines: out.map((i) => '${i.productName} · ${i.warehouseName}').toList(),
            ),
          if (out.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          _AlertCard(
            title: 'Transfer Failures',
            color: AppColors.info,
            lines: transferFailures.isEmpty
                ? const ['No transfer failures found in current history.']
                : transferFailures
                    .map((m) => '${m.productName} · ${m.notes ?? 'No note'}')
                    .toList(),
          ),
        ],
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.color,
    required this.lines,
  });

  final String title;
  final Color color;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${lines.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.md),
            Text(lines[i], style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.items,
    required this.getLabel,
    required this.onChanged,
    this.value,
  });

  final String label;
  final List<T> items;
  final String Function(T item) getLabel;
  final ValueChanged<T?> onChanged;
  final T? value;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            child: Text(getLabel(item)),
          ),
      ],
      onChanged: onChanged,
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
          Expanded(child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StockOpsLoadingView extends StatelessWidget {
  const _StockOpsLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        WmsKpiSkeleton(),
        SizedBox(height: AppSpacing.md),
        WmsSkeletonBox(height: 52, radius: AppSpacing.radiusMd),
        SizedBox(height: AppSpacing.sm),
        WmsSkeletonBox(height: 120, radius: AppSpacing.radiusLg),
      ],
    );
  }
}

class _StockOpsTabDelegate extends SliverPersistentHeaderDelegate {
  _StockOpsTabDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 62;

  @override
  double get maxExtent => 62;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StockOpsTabDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

