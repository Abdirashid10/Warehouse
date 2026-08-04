import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/features/warehouses/presentation/cubit/warehouses_cubit.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouses_enterprise_widgets.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Enterprise Warehouses — mobile-first infrastructure screen aligned with web.
class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen>
    with StaffScopeInitMixin {
  WarehousesCubit? _cubit;
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    setState(() {
      _cubit = WarehousesCubit(repositories.warehouses)..load();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _cubit?.close();
    super.dispose();
  }

  bool _canManage(BuildContext context) {
    final role = context.read<AuthBloc>().state.user?.role;
    return role?.isAdmin == true || role?.isSupervisor == true;
  }

  Future<void> _showWarehouseDialog({Warehouse? existing}) async {
    final colors = WmsUiColors.of(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final capCtrl = TextEditingController(
      text: existing != null ? '${existing.capacity}' : '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          existing == null ? 'New Warehouse' : 'Edit Warehouse',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: locCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: capCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration:
                    const InputDecoration(labelText: 'Capacity (units)'),
                keyboardType: TextInputType.number,
              ),
              if (existing != null && existing.assignedStaff.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Assigned Staff',
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final s in existing.assignedStaff)
                      Chip(
                        label: Text(s.displayName),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    final capacity = num.tryParse(capCtrl.text.trim()) ?? 0;
    try {
      if (existing == null) {
        await _cubit!.create(
          name: nameCtrl.text.trim(),
          location: locCtrl.text.trim(),
          capacity: capacity,
        );
      } else {
        await _cubit!.update(
          id: existing.id,
          name: nameCtrl.text.trim(),
          location: locCtrl.text.trim(),
          capacity: capacity,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save warehouse'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const Scaffold(body: StaffScopeLoadingBody());
    }

    final canManage = _canManage(context);
    final colors = WmsUiColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: AppSpacing.screenPadding,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warehouse_outlined, color: colors.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              'Warehouses',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: BlocProvider.value(
        value: cubit,
        child: BlocBuilder<WarehousesCubit, ResourceState<WarehousesListState>>(
          builder: (context, state) {
            return _WarehousesEnterpriseBody(
              cubit: cubit,
              state: state,
              canManage: canManage,
              nameController: _nameController,
              locationController: _locationController,
              onAdd: () => _showWarehouseDialog(),
              onEdit: (w) => _showWarehouseDialog(existing: w),
              onAssignStaff: (w) => _showWarehouseDialog(existing: w),
              onTransfer: () => context.push(RoutePaths.adminStockOperations),
            );
          },
        ),
      ),
    );
  }
}

class _WarehousesEnterpriseBody extends StatelessWidget {
  const _WarehousesEnterpriseBody({
    required this.cubit,
    required this.state,
    required this.canManage,
    required this.nameController,
    required this.locationController,
    required this.onAdd,
    required this.onEdit,
    required this.onAssignStaff,
    required this.onTransfer,
  });

  final WarehousesCubit cubit;
  final ResourceState<WarehousesListState> state;
  final bool canManage;
  final TextEditingController nameController;
  final TextEditingController locationController;
  final VoidCallback onAdd;
  final void Function(Warehouse warehouse) onEdit;
  final void Function(Warehouse warehouse) onAssignStaff;
  final VoidCallback onTransfer;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);

    if ((state.isLoading || state.status == ResourceStatus.initial) &&
        state.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading warehouses…',
              style: TextStyle(color: colors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (state.isFailure && state.data == null) {
      return WmsErrorState(
        message: state.message ?? 'Failed to load warehouses',
        onRetry: cubit.load,
      );
    }

    final data = state.data;
    if (data == null) {
      return WmsErrorState(
        message: state.message ?? 'Failed to load warehouses',
        onRetry: cubit.load,
      );
    }

    final items = data.filtered;
    final all = data.warehouses;

    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surface,
      onRefresh: cubit.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xxxl,
        ),
        children: [
          WarehousesEnterpriseHeader(
            canManage: canManage,
            onAdd: onAdd,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          WarehousesKpiStrip(summary: data.summary),
          const SizedBox(height: AppSpacing.sectionGap),
          WarehousesSearchPanel(
            nameController: nameController,
            locationController: locationController,
            onNameSearch: cubit.setNameQuery,
            onLocationSearch: cubit.setLocationQuery,
            activeFilterCount: data.activeFilterCount,
            showFilters: data.showFilters,
            onToggleFilters: cubit.toggleFilters,
            onClearFilters: cubit.clearFilters,
            displayCount: items.length,
            totalCount: all.length,
          ),
          if (data.showFilters) ...[
            const SizedBox(height: AppSpacing.md),
            WarehousesFiltersPanel(
              selected: data.capacityFilter,
              onSelected: cubit.setCapacityFilter,
            ),
          ],
          const SizedBox(height: AppSpacing.sectionGap),
          if (all.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: WmsEmptyState(
                title: 'No warehouses',
                message:
                    'Create a warehouse to begin managing infrastructure.',
                icon: Icons.warehouse_outlined,
              ),
            )
          else ...[
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: WmsEmptyState(
                  title: 'No warehouses match filters',
                  message: 'Adjust your search or filter criteria.',
                  icon: Icons.filter_list_off_outlined,
                ),
              )
            else
              ...items.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: WarehouseEnterpriseCard(
                    warehouse: w,
                    canManage: canManage,
                    onView: () => showWarehouseDetailSheet(context, w),
                    onEdit: () => onEdit(w),
                    onTransfer: onTransfer,
                    onAssignStaff: () => onAssignStaff(w),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sectionGap),
            WarehousesAnalyticsSection(warehouses: all),
            const SizedBox(height: AppSpacing.sectionGap),
            WarehousesPerformanceSection(rankings: data.rankings),
          ],
        ],
      ),
    );
  }
}
