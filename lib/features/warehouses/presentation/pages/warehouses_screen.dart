import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/features/warehouses/presentation/cubit/warehouses_cubit.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouse_form_dialog.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouse_premium_atoms.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouse_premium_theme.dart';
import 'package:logisticsmobile/features/warehouses/presentation/widgets/warehouses_enterprise_widgets.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Premium Warehouses — mobile-first infrastructure & capacity control screen.
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
    final result = await showWarehouseFormDialog(
      context: context,
      existing: existing,
    );
    if (result == null || !mounted) return;

    try {
      if (existing == null) {
        await _cubit!.create(
          name: result.name,
          location: result.location,
          capacity: result.capacity,
        );
      } else {
        await _cubit!.update(
          id: existing.id,
          name: result.name,
          location: result.location,
          capacity: result.capacity,
        );
      }
    } catch (_) {
      if (!mounted) return;
      final palette = WarehousePalette.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: palette.colors.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          content: const Text('Could not save warehouse'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const Scaffold(body: StaffScopeLoadingBody());
    }

    final palette = WarehousePalette.of(context);
    final colors = palette.colors;
    final canManage = _canManage(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: AppSpacing.screenPadding,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: palette.brandGradient,
                borderRadius: BorderRadius.circular(9),
                boxShadow: palette.glow(
                  palette.brand,
                  opacity: 0.34,
                  blur: 12,
                  dy: 4,
                  spread: -3,
                ),
              ),
              child: const Icon(
                Icons.warehouse_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Text(
              'Warehouses',
              style: WmsDesignTokens.cardTitle(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.pageGradient),
        child: BlocProvider.value(
          value: cubit,
          child: BlocBuilder<WarehousesCubit, ResourceState<WarehousesListState>>(
            builder: (context, state) {
              return _WarehousesBody(
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
      ),
    );
  }
}

class _WarehousesBody extends StatelessWidget {
  const _WarehousesBody({
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
    final palette = WarehousePalette.of(context);
    final colors = palette.colors;

    if ((state.isLoading || state.status == ResourceStatus.initial) &&
        state.data == null) {
      return _WarehousesLoadingView(palette: palette);
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
      color: palette.brand,
      backgroundColor: colors.surface,
      onRefresh: cubit.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xxxl + AppSpacing.lg,
        ),
        children: [
          WarehousesEnterpriseHeader(canManage: canManage, onAdd: onAdd),
          const SizedBox(height: AppSpacing.xl + 2),
          WarehousesKpiStrip(summary: data.summary),
          const SizedBox(height: AppSpacing.xl),
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
          const SizedBox(height: AppSpacing.xl),
          if (all.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: WmsEmptyState(
                title: 'No warehouses',
                message: 'Create a warehouse to begin managing infrastructure.',
                icon: Icons.warehouse_outlined,
              ),
            )
          else ...[
            WarehouseSectionHeading(
              eyebrow: 'Network',
              title: 'Facilities',
              subtitle: '${items.length} of ${all.length} shown',
              trailing: WarehouseGlowBadge(
                icon: Icons.warehouse_rounded,
                color: palette.accentBlue,
                size: 38,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
                  padding: const EdgeInsets.only(bottom: AppSpacing.md + 2),
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
            const SizedBox(height: AppSpacing.sm),
            WarehousesAnalyticsSection(warehouses: all),
            const SizedBox(height: AppSpacing.xl + 2),
            WarehousesPerformanceSection(rankings: data.rankings),
          ],
        ],
      ),
    );
  }
}

/// Branded loading state — keeps the premium chrome while data resolves.
class _WarehousesLoadingView extends StatelessWidget {
  const _WarehousesLoadingView({required this.palette});

  final WarehousePalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: palette.brand,
                  backgroundColor: palette.insetFill,
                ),
                WarehouseGlowBadge(
                  icon: Icons.warehouse_rounded,
                  color: palette.brand,
                  size: 38,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loading warehouses…',
            style: WmsDesignTokens.body(context).copyWith(
              color: palette.colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
