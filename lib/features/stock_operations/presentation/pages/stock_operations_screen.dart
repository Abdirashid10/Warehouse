import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/create_movement_input.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/cubit/movements_cubit.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/utils/movement_form_utils.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_movements_widgets.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_ops_form_widgets.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_ops_premium_theme.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_ops_premium_widgets.dart';

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

  /// Badge count for the Alerts tab — mirrors what [_StockAlertsTab] lists.
  static int _alertCount(MovementsViewState data) {
    final low = data.inventory
        .where((i) => i.stockStatus == WmsStockStatuses.lowStock)
        .length;
    final out = data.inventory
        .where((i) => i.stockStatus == WmsStockStatuses.outOfStock)
        .length;
    final failures = data.movements
        .where((m) =>
            m.type == WmsMovementTypes.transfer &&
            (m.notes ?? '').toLowerCase().contains('fail'))
        .length;
    return low + out + failures;
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

          final palette = StockOpsPalette.of(context);

          return DefaultTabController(
            length: 6,
            initialIndex: widget.initialTab.clamp(0, 5),
            child: Scaffold(
              backgroundColor: colors.background,
              appBar: AppBar(
                title: Text(widget.title),
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
              ),
              body: DecoratedBox(
                decoration: BoxDecoration(gradient: palette.pageGradient),
                child: RefreshIndicator(
                color: palette.brand,
                backgroundColor: colors.surface,
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
                          padding: const EdgeInsets.only(
                            left: AppSpacing.screenPadding,
                            top: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                          ),
                          child: StockOpsTabBar(
                            tabs: [
                              const StockOpsTab(
                                label: 'Receive',
                                icon: Icons.download_rounded,
                              ),
                              const StockOpsTab(
                                label: 'Dispatch',
                                icon: Icons.upload_rounded,
                              ),
                              const StockOpsTab(
                                label: 'Transfer',
                                icon: Icons.swap_horiz_rounded,
                              ),
                              const StockOpsTab(
                                label: 'Return',
                                icon: Icons.assignment_return_outlined,
                              ),
                              StockOpsTab(
                                label: 'History',
                                icon: Icons.history_rounded,
                                badge: data.movements.length,
                              ),
                              StockOpsTab(
                                label: 'Alerts',
                                icon: Icons.warning_amber_rounded,
                                badge: _alertCount(data),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: true,
                      // No shared horizontal inset: each tab pads its own
                      // scrolling content so the pinned submit bar can span
                      // the full width.
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
                  ],
                ),
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
    final palette = StockOpsPalette.of(context);

    return StockOpsHeroBanner(
      title: title,
      subtitle: 'Inbound, outbound, transfer and return workflows',
      metrics: [
        StockOpsBentoMetric(
          label: "Today's Inbound",
          value: '${data.todaysInbound}',
          spec: StockOpsKinds.inbound,
          accent: const Color(0xFF6EE7B7),
        ),
        StockOpsBentoMetric(
          label: "Today's Outbound",
          value: '${data.todaysOutbound}',
          spec: StockOpsKinds.outbound,
          accent: const Color(0xFFFCD34D),
        ),
        StockOpsBentoMetric(
          label: "Today's Transfers",
          value: '${data.todaysTransfers}',
          spec: StockOpsKinds.transfer,
          accent: const Color(0xFF7DD3FC),
        ),
        StockOpsBentoMetric(
          label: "Today's Returns",
          value: '${data.todaysReturns}',
          spec: StockOpsKinds.returned,
          accent: palette.isDark
              ? const Color(0xFFC4B5FD)
              : const Color(0xFFC4B5FD),
        ),
      ],
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
  void initState() {
    super.initState();
    // The summary and the availability warning read these controllers, so they
    // have to rebuild as the operator types. Previously the "exceeds available"
    // message only refreshed when some other setState happened to fire.
    _qtyCtrl.addListener(_onFormChanged);
    _notesCtrl.addListener(_onFormChanged);
    _supplierCtrl.addListener(_onFormChanged);
    _referenceCtrl.addListener(_onFormChanged);
    _destinationCtrl.addListener(_onFormChanged);
    _batchCtrl.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _qtyCtrl.removeListener(_onFormChanged);
    _notesCtrl.removeListener(_onFormChanged);
    _supplierCtrl.removeListener(_onFormChanged);
    _referenceCtrl.removeListener(_onFormChanged);
    _destinationCtrl.removeListener(_onFormChanged);
    _batchCtrl.removeListener(_onFormChanged);
    _qtyCtrl.dispose();
    _batchCtrl.dispose();
    _supplierCtrl.dispose();
    _referenceCtrl.dispose();
    _destinationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Reason the submit button is not ready yet, or null when it is.
  String? _blockingHint({required num available}) {
    if (widget.requiresSourceAndDestination) {
      if (_sourceWarehouse == null || _destinationWarehouse == null) {
        return 'Select source and destination warehouses';
      }
      if (_sourceWarehouse!.id == _destinationWarehouse!.id) {
        return 'Source and destination must differ';
      }
    } else if (_warehouse == null) {
      return 'Select a warehouse';
    }
    if (_product == null) return 'Select a product';

    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) return 'Enter a quantity greater than zero';
    if (widget.enforceAvailable && qty > available) {
      return 'Quantity exceeds available stock';
    }
    if (widget.requiresDestination && _destinationCtrl.text.trim().isEmpty) {
      return 'Destination is required for dispatch';
    }

    final reasonError = validateMovementReason(
      buildMovementReason(
        notes: _notesCtrl.text.trim(),
        supplier: _supplierCtrl.text.trim(),
        referenceNumber: _referenceCtrl.text.trim(),
      ),
    );
    if (reasonError != null) return reasonError;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
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

    final qty = num.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final overAvailable = widget.enforceAvailable && qty > available;
    final blocking = _blockingHint(available: available);

    final optionalFilled = [
      _batchCtrl.text.trim(),
      _supplierCtrl.text.trim(),
      _referenceCtrl.text.trim(),
    ].where((v) => v.isNotEmpty).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            children: [
              StockOpsSummaryCard(
                accent: overAvailable ? colors.error : colors.primary,
                warning: overAvailable
                    ? 'Cannot ${widget.type == WmsMovementTypes.transfer ? 'transfer' : 'dispatch'} more than the available quantity.'
                    : null,
                metrics: [
                  StockOpsSummaryMetric(
                    label: 'Available Stock',
                    value: _product == null || selectedWarehouse == null
                        ? '—'
                        : WmsFormatters.quantity(available),
                    emphasis: true,
                    tone: overAvailable ? colors.error : null,
                  ),
                  StockOpsSummaryMetric(
                    label: 'Reorder Level',
                    value: _product?.minStockThreshold != null
                        ? WmsFormatters.quantity(_product!.minStockThreshold)
                        : '—',
                  ),
                  StockOpsSummaryMetric(
                    label: 'Warehouse',
                    value: selectedWarehouse?.name ?? 'Not selected',
                  ),
                ],
              ),
              const SizedBox(height: StockOpsUi.sectionGap),
              StockOpsFormSection(
                title: 'Location',
                subtitle: widget.requiresSourceAndDestination
                    ? 'Where stock moves from and to'
                    : 'Where this movement is recorded',
                icon: Icons.warehouse_outlined,
                children: [
                  if (!widget.requiresSourceAndDestination)
                    StockOpsDropdownField<WarehouseOption>(
                      label: 'Warehouse',
                      required: true,
                      value: _warehouse,
                      items: warehouses,
                      getLabel: (w) => w.name,
                      onChanged: (v) => setState(() => _warehouse = v),
                    )
                  else ...[
                    StockOpsDropdownField<WarehouseOption>(
                      label: 'Source Warehouse',
                      required: true,
                      value: _sourceWarehouse,
                      items: warehouses,
                      getLabel: (w) => w.name,
                      onChanged: (v) => setState(() => _sourceWarehouse = v),
                    ),
                    StockOpsDropdownField<WarehouseOption>(
                      label: 'Destination Warehouse',
                      required: true,
                      value: _destinationWarehouse,
                      items: warehouses,
                      getLabel: (w) => w.name,
                      onChanged: (v) =>
                          setState(() => _destinationWarehouse = v),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: StockOpsUi.sectionGap),
              StockOpsFormSection(
                title: 'Product & Quantity',
                subtitle: 'What is moving, and how much',
                icon: Icons.inventory_2_outlined,
                children: [
                  StockOpsDropdownField<Product>(
                    label: 'Product',
                    required: true,
                    value: _product,
                    items: products,
                    getLabel: (p) => '${p.name} · ${p.sku}',
                    onChanged: (v) => setState(() => _product = v),
                  ),
                  StockOpsTextField(
                    controller: _qtyCtrl,
                    label: 'Quantity',
                    required: true,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.numbers_rounded,
                    errorText: overAvailable
                        ? 'Only ${WmsFormatters.quantity(available)} available'
                        : null,
                  ),
                  if (widget.requiresDestination)
                    StockOpsTextField(
                      controller: _destinationCtrl,
                      label: 'Destination',
                      required: true,
                      hint: 'Customer or delivery location',
                      prefixIcon: Icons.place_outlined,
                    ),
                ],
              ),
              const SizedBox(height: StockOpsUi.sectionGap),
              StockOpsFormSection(
                title: 'Reason & Notes',
                // The backend rejects a reason under 10 characters, so this is
                // surfaced up front rather than only on submit.
                subtitle: 'Required — at least '
                    '$movementReasonMinLength characters',
                icon: Icons.edit_note_rounded,
                children: [
                  StockOpsTextField(
                    controller: _notesCtrl,
                    label: 'Notes',
                    required: true,
                    maxLines: 3,
                    hint: 'Why is this movement being recorded?',
                    helper:
                        '${_notesCtrl.text.trim().length}/$movementReasonMinLength characters minimum',
                  ),
                ],
              ),
              const SizedBox(height: StockOpsUi.sectionGap),
              StockOpsFormSection(
                title: 'Additional Details',
                subtitle: 'Optional traceability',
                icon: Icons.qr_code_2_rounded,
                collapsible: true,
                initiallyExpanded: false,
                filledCount: optionalFilled,
                children: [
                  StockOpsTextField(
                    controller: _batchCtrl,
                    label: 'Batch Number',
                    prefixIcon: Icons.tag_rounded,
                  ),
                  StockOpsTextField(
                    controller: _supplierCtrl,
                    label: 'Supplier',
                    prefixIcon: Icons.local_shipping_outlined,
                  ),
                  StockOpsTextField(
                    controller: _referenceCtrl,
                    label: 'Reference Number',
                    prefixIcon: Icons.receipt_long_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
        StockOpsSubmitBar(
          label: 'Submit Operation',
          icon: Icons.send_rounded,
          submitting: _submitting,
          enabled: blocking == null,
          hint: blocking,
          onSubmit: () => _submit(context),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final colors = WmsUiColors.of(context);
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
          backgroundColor: colors.success,
        ),
      );
      _clearForm();
    } on ApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.fromApiException(e)),
          backgroundColor: colors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not complete the operation. Check your connection.'),
          backgroundColor: colors.error,
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
  void initState() {
    super.initState();
    _qtyCtrl.addListener(_onFormChanged);
    _reasonCtrl.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _qtyCtrl.removeListener(_onFormChanged);
    _reasonCtrl.removeListener(_onFormChanged);
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  String? _blockingHint() {
    if (_warehouse == null) return 'Select a warehouse';
    if (_product == null) return 'Select a product';
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) return 'Enter a quantity greater than zero';
    final reasonError = validateMovementReason(
      buildMovementReason(notes: '', returnReason: _reasonCtrl.text.trim()),
    );
    if (reasonError != null) return reasonError;
    return null;
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
    final blocking = _blockingHint();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            children: [
              StockOpsSummaryCard(
                metrics: [
                  StockOpsSummaryMetric(
                    label: 'Available Stock',
                    value: _product == null || _warehouse == null
                        ? '—'
                        : WmsFormatters.quantity(available),
                    emphasis: true,
                  ),
                  StockOpsSummaryMetric(
                    label: 'Warehouse',
                    value: _warehouse?.name ?? 'Not selected',
                  ),
                ],
              ),
              const SizedBox(height: StockOpsUi.sectionGap),
              StockOpsFormSection(
                title: 'Location & Product',
                subtitle: 'What is being returned, and where to',
                icon: Icons.assignment_return_outlined,
                children: [
                  StockOpsDropdownField<WarehouseOption>(
                    label: 'Warehouse',
                    required: true,
                    value: _warehouse,
                    items: warehouses,
                    getLabel: (w) => w.name,
                    onChanged: (v) => setState(() => _warehouse = v),
                  ),
                  StockOpsDropdownField<Product>(
                    label: 'Product',
                    required: true,
                    value: _product,
                    items: widget.data.catalog,
                    getLabel: (p) => '${p.name} · ${p.sku}',
                    onChanged: (v) => setState(() => _product = v),
                  ),
                  StockOpsTextField(
                    controller: _qtyCtrl,
                    label: 'Quantity',
                    required: true,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.numbers_rounded,
                  ),
                ],
              ),
              const SizedBox(height: StockOpsUi.sectionGap),
              StockOpsFormSection(
                title: 'Return Reason',
                subtitle: 'Required — at least '
                    '$movementReasonMinLength characters',
                icon: Icons.edit_note_rounded,
                children: [
                  StockOpsTextField(
                    controller: _reasonCtrl,
                    label: 'Return Reason',
                    required: true,
                    maxLines: 3,
                    hint: 'Why is this stock being returned?',
                    helper:
                        '${_reasonCtrl.text.trim().length}/$movementReasonMinLength characters minimum',
                  ),
                ],
              ),
            ],
          ),
        ),
        StockOpsSubmitBar(
          label: 'Submit Return',
          icon: Icons.undo_rounded,
          submitting: _submitting,
          enabled: blocking == null,
          hint: blocking,
          onSubmit: () => _submitReturn(context),
        ),
      ],
    );
  }

  Future<void> _submitReturn(BuildContext context) async {
    final colors = WmsUiColors.of(context);
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
        SnackBar(
          content: Text('Return recorded successfully.'),
          backgroundColor: colors.success,
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
          backgroundColor: colors.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not record return. Check your connection.'),
          backgroundColor: colors.error,
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

  static const _filterTypes = [
    WmsMovementTypes.inbound,
    WmsMovementTypes.outbound,
    WmsMovementTypes.transfer,
    WmsMovementTypes.returnType,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = StockOpsPalette.of(context);
    final movements = data.movements;

    void applyFilter(String? type) {
      onTypeFilter(type);
      cubit.loadAuditTrail(type: type);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        // Clears the host's bottom navigation bar plus the gesture inset, so
        // the last card is never trapped behind it.
        AppSpacing.xxxl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        StockOpsSectionIntro(
          eyebrow: 'Audit trail',
          title: 'Movement History',
          subtitle: '${movements.length} recorded movements',
          trailing: StockOpsIconWell(
            icon: Icons.history_rounded,
            color: palette.brand,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StockOpsSearchField(
          controller: searchController,
          hint: 'Search product, SKU, or operator…',
          onChanged: onSearch,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            children: [
              StockOpsFilterPill(
                label: 'All types',
                selected: data.typeFilter == null,
                onTap: () => applyFilter(null),
              ),
              for (final type in _filterTypes) ...[
                const SizedBox(width: AppSpacing.sm),
                StockOpsFilterPill(
                  label: WmsMovementTypes.label(type),
                  icon: StockOpsKinds.fromType(type).icon,
                  accent: palette.accentForType(type),
                  selected: data.typeFilter == type,
                  onTap: () =>
                      applyFilter(data.typeFilter == type ? null : type),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (movements.isEmpty)
          const StockOpsEmptyState(
            icon: Icons.inbox_rounded,
            title: 'No movements found',
            message:
                'Nothing matches the current search or type filter. Clear them '
                'to see the full audit trail.',
          )
        else
          ...movements.map(
            (movement) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: StockOpsHistoryCard(
                movement: movement,
                onTap: () => onOpenDetail(movement),
              ),
            ),
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

    final palette = StockOpsPalette.of(context);
    final total = low.length + out.length + transferFailures.length;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xxxl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        StockOpsSectionIntro(
          eyebrow: 'Exceptions',
          title: 'Stock Alerts',
          subtitle: total == 0
              ? 'Everything is within tolerance'
              : '$total items need attention',
          trailing: StockOpsIconWell(
            icon: Icons.warning_amber_rounded,
            color: total == 0 ? palette.emerald : palette.severityCritical,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Out of stock leads: it blocks fulfilment outright, while low stock
        // only threatens to.
        StockOpsAlertSection(
          title: 'Out of Stock',
          subtitle: 'Zero units available — fulfilment is blocked',
          icon: Icons.remove_shopping_cart_rounded,
          severity: StockAlertSeverity.critical,
          emptyMessage: 'No products are out of stock.',
          entries: [
            for (final item in out)
              StockOpsAlertEntry(
                title: item.productName,
                subtitle: item.warehouseName,
                trailing: '0',
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        StockOpsAlertSection(
          title: 'Low Stock',
          subtitle: 'Below the reorder threshold',
          icon: Icons.trending_down_rounded,
          severity: StockAlertSeverity.warning,
          emptyMessage: 'No products are below their reorder point.',
          entries: [
            for (final item in low)
              StockOpsAlertEntry(
                title: item.productName,
                subtitle: item.warehouseName,
                trailing: WmsFormatters.quantity(item.quantity),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        StockOpsAlertSection(
          title: 'Transfer Failures',
          subtitle: 'Transfers flagged as failed in the audit trail',
          icon: Icons.sync_problem_rounded,
          severity: StockAlertSeverity.info,
          emptyMessage: 'No transfer failures in the current history window.',
          entries: [
            for (final movement in transferFailures)
              StockOpsAlertEntry(
                title: movement.productName,
                subtitle: movement.notes ?? 'No note recorded',
                trailing: WmsFormatters.quantity(movement.quantity),
              ),
          ],
        ),
      ],
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
  double get minExtent => StockOpsTabBar.height + AppSpacing.md;

  @override
  double get maxExtent => StockOpsTabBar.height + AppSpacing.md;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StockOpsTabDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

