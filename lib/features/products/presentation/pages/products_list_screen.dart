import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/di/staff_repositories.dart';
import 'package:logisticsmobile/core/di/staff_scope_init_mixin.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/presentation/cubit/products_catalog_cubit.dart';
import 'package:logisticsmobile/features/products/presentation/widgets/product_detail_sheet.dart';
import 'package:logisticsmobile/features/products/presentation/widgets/product_form_sheet.dart'
    hide showProductDetailSheet;
import 'package:logisticsmobile/features/products/presentation/widgets/products_enterprise_widgets.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Enterprise Products — mobile-first master data screen aligned with web.
class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen>
    with StaffScopeInitMixin {
  ProductsCatalogCubit? _cubit;
  final _searchController = TextEditingController();

  @override
  void onStaffScopeReady(StaffRepositories repositories) {
    setState(() {
      _cubit = ProductsCatalogCubit(
        repositories.products,
        repositories.inventory,
      )..load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit?.close();
    super.dispose();
  }

  bool _canManage(BuildContext context) {
    final role = context.read<AuthBloc>().state.user?.role;
    return role?.isAdmin == true || role?.isSupervisor == true;
  }

  bool _isAdmin(BuildContext context) {
    return context.read<AuthBloc>().state.user?.role.isAdmin == true;
  }

  void _openForm(
    BuildContext context,
    ProductsCatalogCubit cubit, {
    Product? product,
  }) {
    final data = cubit.state.data;
    if (data == null) return;
    showProductFormSheet(
      context,
      cubit: cubit,
      categories: data.categories,
      existing: product,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductsCatalogCubit cubit,
    Product product,
  ) async {
    final colors = WmsUiColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Delete product?',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          '${product.sku} — ${product.name}\n\nThis action is irreversible. Products with inventory records cannot be deleted.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await cubit.deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted.')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessageMapper.fromApiException(e)),
            backgroundColor: colors.error,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not delete product.'),
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
    final isAdmin = _isAdmin(context);
    final colors = WmsUiColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: BlocProvider.value(
        value: cubit,
        child: BlocBuilder<ProductsCatalogCubit,
            ResourceState<ProductsCatalogState>>(
          builder: (context, state) {
            if ((state.isLoading || state.status == ResourceStatus.initial) &&
                state.data == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: colors.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Loading products…',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state.isFailure && state.data == null) {
              return WmsErrorState(
                message: state.message ?? 'Failed to load products',
                onRetry: cubit.load,
              );
            }

            final data = state.data;
            if (data == null) {
              return WmsErrorState(
                message: state.message ?? 'Failed to load products',
                onRetry: cubit.load,
              );
            }

            final items = data.filtered;

            return RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.surface,
              onRefresh: cubit.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: ProductsMobileHeader(
                      canManage: canManage,
                      onAdd: () => _openForm(context, cubit),
                      onBack: context.canPop() ? () => context.pop() : null,
                    ),
                  ),
                  if (data.categoriesError != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: MobileUi.screenHorizontalInsetsOf(context),
                        child: _WarningBanner(
                          text: 'Categories: ${data.categoriesError}',
                        ),
                      ),
                    ),
                  if (data.warehousesError != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: MobileUi.screenHorizontalInsetsOf(context).copyWith(
                          top: AppSpacing.sm,
                        ),
                        child: _WarningBanner(
                          text: 'Warehouses: ${data.warehousesError}',
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: MobileUi.dashboardSectionGap),
                  ),
                  SliverToBoxAdapter(
                    child: ProductsMobileKpiGrid(
                      summary: data.summary,
                      categoryCount: data.categories.length,
                      onLowStock: () => cubit.setStatusFilter('Low Stock'),
                      onOutOfStock: () => cubit.setStatusFilter('Out Of Stock'),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: MobileUi.dashboardSectionGap),
                  ),
                  SliverToBoxAdapter(
                    child: ProductsMobileSearchSection(
                      searchController: _searchController,
                      onSearch: cubit.setSearchQuery,
                      categories: data.categories,
                      warehouses: data.warehouses,
                      categoryFilterId: data.categoryFilterId,
                      warehouseFilterId: data.warehouseFilterId,
                      warehouseFilterLoading: data.warehouseFilterLoading,
                      onCategory: cubit.setCategoryFilter,
                      onWarehouse: cubit.setWarehouseFilter,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: MobileUi.dashboardSectionGap),
                  ),
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: WmsEmptyState(
                        title: data.products.isEmpty
                            ? 'No products in catalog'
                            : 'No products match filters',
                        message: data.products.isEmpty
                            ? 'Create a product to begin building your inventory catalog.'
                            : 'Adjust your search or filter criteria.',
                        icon: Icons.inventory_2_outlined,
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: ProductsMobileCardList(
                        products: items,
                        canManage: canManage,
                        isAdmin: isAdmin,
                        onView: (p) => showProductDetailSheet(context, p),
                        onEdit: (p) => _openForm(context, cubit, product: p),
                        onStockHistory: () =>
                            context.push(RoutePaths.adminStockMovements),
                        onTransfer: () =>
                            context.push(RoutePaths.adminStockOperations),
                        onDelete: isAdmin
                            ? (p) => _confirmDelete(context, cubit, p)
                            : null,
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
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Material(
      color: colors.warning.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          text,
          style: TextStyle(color: colors.warning, fontSize: 12),
        ),
      ),
    );
  }
}
