import 'dart:async';



import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:logisticsmobile/core/errors/api_exception.dart';

import 'package:logisticsmobile/core/errors/error_message_mapper.dart';

import 'package:logisticsmobile/core/presentation/resource_state.dart';

import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';

import 'package:logisticsmobile/features/inventory/domain/repositories/inventory_repository.dart';

import 'package:logisticsmobile/features/products/domain/entities/create_product_input.dart';

import 'package:logisticsmobile/features/products/domain/entities/product.dart';

import 'package:logisticsmobile/features/products/domain/entities/product_category.dart';

import 'package:logisticsmobile/features/products/domain/entities/products_summary.dart';

import 'package:logisticsmobile/features/products/domain/repositories/products_repository.dart';



enum ProductSortField { sku, name, price, stock, updated }



class ProductsCatalogState {

  const ProductsCatalogState({

    required this.products,

    required this.summary,

    required this.categories,

    this.warehouses = const [],

    this.skuQuery = '',

    this.nameQuery = '',

    this.barcodeQuery = '',

    this.searchQuery = '',

    this.categoryFilterId,

    this.warehouseFilterId,

    this.statusFilter,

    this.showFilters = false,

    this.sortField = ProductSortField.sku,

    this.sortAscending = true,

    this.categoriesError,

    this.warehousesError,

    this.warehouseProductIds = const {},

    this.warehouseProductSkus = const {},

    this.warehouseFilterLoading = false,

  });



  final List<Product> products;

  final ProductsSummary summary;

  final List<ProductCategory> categories;

  final List<WarehouseOption> warehouses;

  final String skuQuery;

  final String nameQuery;

  final String barcodeQuery;

  /// Unified mobile search — matches SKU, name, or barcode (OR logic).
  final String searchQuery;

  final String? categoryFilterId;

  final String? warehouseFilterId;

  final String? statusFilter;

  final bool showFilters;

  final ProductSortField sortField;

  final bool sortAscending;

  final String? categoriesError;

  final String? warehousesError;

  final Set<String> warehouseProductIds;

  final Set<String> warehouseProductSkus;

  final bool warehouseFilterLoading;



  List<Product> get filtered {

    var list = [...products];



    final unified = searchQuery.trim().toLowerCase();

    if (unified.isNotEmpty) {

      list = list

          .where(

            (p) =>

                p.sku.toLowerCase().contains(unified) ||

                p.name.toLowerCase().contains(unified) ||

                (p.barcode ?? '').toLowerCase().contains(unified),

          )

          .toList();

    } else {

      final sku = skuQuery.trim().toLowerCase();

      if (sku.isNotEmpty) {

        list = list.where((p) => p.sku.toLowerCase().contains(sku)).toList();

      }



      final name = nameQuery.trim().toLowerCase();

      if (name.isNotEmpty) {

        list = list.where((p) => p.name.toLowerCase().contains(name)).toList();

      }



      final barcode = barcodeQuery.trim().toLowerCase();

      if (barcode.isNotEmpty) {

        list = list

            .where((p) => (p.barcode ?? '').toLowerCase().contains(barcode))

            .toList();

      }

    }



    if (categoryFilterId != null && categoryFilterId!.isNotEmpty) {

      list = list.where((p) => p.categoryId == categoryFilterId).toList();

    }



    if (warehouseFilterId != null && warehouseFilterId!.isNotEmpty) {

      list = list

          .where(

            (p) =>

                warehouseProductIds.contains(p.id) ||

                warehouseProductSkus.contains(p.sku),

          )

          .toList();

    }



    if (statusFilter != null && statusFilter!.isNotEmpty) {

      list = list.where((p) => p.stockStatusLabel == statusFilter).toList();

    }



    list.sort((a, b) {

      final dir = sortAscending ? 1 : -1;

      int cmp;

      switch (sortField) {

        case ProductSortField.name:

          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());

        case ProductSortField.price:

          cmp = (a.unitPrice ?? 0).compareTo(b.unitPrice ?? 0);

        case ProductSortField.stock:

          cmp = (a.totalStock ?? 0).compareTo(b.totalStock ?? 0);

        case ProductSortField.updated:

          final au = a.updatedAt?.millisecondsSinceEpoch ?? 0;

          final bu = b.updatedAt?.millisecondsSinceEpoch ?? 0;

          cmp = au.compareTo(bu);

        case ProductSortField.sku:

          cmp = a.sku.toLowerCase().compareTo(b.sku.toLowerCase());

      }

      return cmp * dir;

    });

    return list;

  }



  int get activeFilterCount =>

      (categoryFilterId != null && categoryFilterId!.isNotEmpty ? 1 : 0) +

      (warehouseFilterId != null && warehouseFilterId!.isNotEmpty ? 1 : 0) +

      (statusFilter != null && statusFilter!.isNotEmpty ? 1 : 0);



  ProductsCatalogState copyWith({

    List<Product>? products,

    ProductsSummary? summary,

    List<ProductCategory>? categories,

    List<WarehouseOption>? warehouses,

    String? skuQuery,

    String? nameQuery,

    String? barcodeQuery,

    String? searchQuery,

    String? categoryFilterId,

    String? warehouseFilterId,

    String? statusFilter,

    bool? showFilters,

    ProductSortField? sortField,

    bool? sortAscending,

    String? categoriesError,

    String? warehousesError,

    Set<String>? warehouseProductIds,

    Set<String>? warehouseProductSkus,

    bool? warehouseFilterLoading,

    bool clearCategoryFilter = false,

    bool clearWarehouseFilter = false,

    bool clearStatusFilter = false,

    bool clearSearchQuery = false,

    bool clearCategoriesError = false,

    bool clearWarehousesError = false,

  }) {

    return ProductsCatalogState(

      products: products ?? this.products,

      summary: summary ?? this.summary,

      categories: categories ?? this.categories,

      warehouses: warehouses ?? this.warehouses,

      skuQuery: skuQuery ?? this.skuQuery,

      nameQuery: nameQuery ?? this.nameQuery,

      barcodeQuery: barcodeQuery ?? this.barcodeQuery,

      searchQuery: clearSearchQuery ? '' : (searchQuery ?? this.searchQuery),

      categoryFilterId: clearCategoryFilter

          ? null

          : (categoryFilterId ?? this.categoryFilterId),

      warehouseFilterId: clearWarehouseFilter

          ? null

          : (warehouseFilterId ?? this.warehouseFilterId),

      statusFilter:

          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),

      showFilters: showFilters ?? this.showFilters,

      sortField: sortField ?? this.sortField,

      sortAscending: sortAscending ?? this.sortAscending,

      categoriesError: clearCategoriesError

          ? null

          : (categoriesError ?? this.categoriesError),

      warehousesError: clearWarehousesError

          ? null

          : (warehousesError ?? this.warehousesError),

      warehouseProductIds: warehouseProductIds ?? this.warehouseProductIds,

      warehouseProductSkus: warehouseProductSkus ?? this.warehouseProductSkus,

      warehouseFilterLoading:

          warehouseFilterLoading ?? this.warehouseFilterLoading,

    );

  }

}



class ProductsCatalogCubit extends Cubit<ResourceState<ProductsCatalogState>> {

  ProductsCatalogCubit(this._repository, this._inventory)

      : super(const ResourceState.initial());



  final ProductsRepository _repository;

  final InventoryRepository _inventory;



  static List<ProductCategory> _mergeCategories(

    List<Product> products,

    List<ProductCategory> fromApi,

  ) {

    final byId = <String, ProductCategory>{

      for (final c in fromApi) c.id: c,

    };

    for (final p in products) {

      final id = p.categoryId;

      final name = p.category;

      if (id != null &&

          id.isNotEmpty &&

          name != null &&

          name.isNotEmpty &&

          !byId.containsKey(id)) {

        byId[id] = ProductCategory(id: id, name: name);

      }

    }

    final list = byId.values.toList()

      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return list;

  }



  Future<void> load() async {

    final current = state.data;

    emit(ResourceState.loading(data: current));

    try {

      final catalog = await _repository.getCatalog();



      List<ProductCategory> categories = [];

      String? categoriesError;

      try {

        categories = await _repository.getCategories();

      } on ApiException catch (e) {

        categoriesError = ErrorMessageMapper.fromApiException(e);

      } catch (_) {

        categoriesError = 'Could not load categories';

      }

      categories = _mergeCategories(catalog.products, categories);



      List<WarehouseOption> warehouses = [];

      String? warehousesError;

      try {

        warehouses = await _inventory.getWarehouses();

      } on ApiException catch (e) {

        warehousesError = ErrorMessageMapper.fromApiException(e);

      } catch (_) {

        warehousesError = 'Could not load warehouses';

      }



      final base = (current ??

              const ProductsCatalogState(

                products: [],

                summary: ProductsSummary(),

                categories: [],

              ))

          .copyWith(

        products: catalog.products,

        summary: catalog.summary,

        categories: categories,

        warehouses: warehouses,

        categoriesError: categoriesError,

        warehousesError: warehousesError,

        clearCategoriesError: categoriesError == null,

        clearWarehousesError: warehousesError == null,

      );



      emit(ResourceState.success(base));



      final warehouseId = base.warehouseFilterId;

      if (warehouseId != null && warehouseId.isNotEmpty) {

        await _applyWarehouseFilter(warehouseId);

      }

    } on ApiException catch (e) {

      emit(ResourceState.failure(

        ErrorMessageMapper.fromApiException(e),

        data: current,

      ));

    } catch (_) {

      emit(ResourceState.failure('Failed to load products', data: current));

    }

  }



  void setSkuQuery(String query) {

    final data = state.data;

    if (data == null) return;

    emit(ResourceState.success(data.copyWith(skuQuery: query)));

  }



  void setNameQuery(String query) {

    final data = state.data;

    if (data == null) return;

    emit(ResourceState.success(data.copyWith(nameQuery: query)));

  }



  void setBarcodeQuery(String query) {

    final data = state.data;

    if (data == null) return;

    emit(ResourceState.success(data.copyWith(barcodeQuery: query)));

  }



  void setSearchQuery(String query) {

    final data = state.data;

    if (data == null) return;

    emit(ResourceState.success(data.copyWith(searchQuery: query)));

  }



  void setCategoryFilter(String? categoryId) {

    final data = state.data;

    if (data == null) return;

    emit(

      ResourceState.success(

        data.copyWith(

          categoryFilterId: categoryId,

          clearCategoryFilter: categoryId == null,

        ),

      ),

    );

  }



  Future<void> setWarehouseFilter(String? warehouseId) async {

    final data = state.data;

    if (data == null) return;



    if (warehouseId == null || warehouseId.isEmpty) {

      emit(

        ResourceState.success(

          data.copyWith(

            clearWarehouseFilter: true,

            warehouseProductIds: const {},

            warehouseProductSkus: const {},

            warehouseFilterLoading: false,

          ),

        ),

      );

      return;

    }



    emit(

      ResourceState.success(

        data.copyWith(

          warehouseFilterId: warehouseId,

          warehouseFilterLoading: true,

        ),

      ),

    );

    await _applyWarehouseFilter(warehouseId);

  }



  Future<void> _applyWarehouseFilter(String warehouseId) async {

    final data = state.data;

    if (data == null) return;



    try {

      final tracking =

          await _inventory.getTracking(warehouseId: warehouseId);

      final ids = <String>{};

      final skus = <String>{};

      for (final item in tracking.items) {

        final productId = item.productId;

        if (productId != null && productId.isNotEmpty) {

          ids.add(productId);

        }

        skus.add(item.sku);

      }



      final current = state.data;

      if (current == null || current.warehouseFilterId != warehouseId) return;



      emit(

        ResourceState.success(

          current.copyWith(

            warehouseProductIds: ids,

            warehouseProductSkus: skus,

            warehouseFilterLoading: false,

          ),

        ),

      );

    } catch (_) {

      final current = state.data;

      if (current == null) return;

      emit(

        ResourceState.success(

          current.copyWith(

            warehouseFilterLoading: false,

            warehouseProductIds: const {},

            warehouseProductSkus: const {},

          ),

        ),

      );

    }

  }



  void setStatusFilter(String? status) {

    final data = state.data;

    if (data == null) return;

    emit(

      ResourceState.success(

        data.copyWith(

          statusFilter: status,

          clearStatusFilter: status == null,

        ),

      ),

    );

  }



  void setSort(ProductSortField field) {

    final data = state.data;

    if (data == null) return;

    final sameField = data.sortField == field;

    emit(

      ResourceState.success(

        data.copyWith(

          sortField: field,

          sortAscending: sameField ? !data.sortAscending : true,

        ),

      ),

    );

  }



  void toggleFilters() {

    final data = state.data;

    if (data == null) return;

    emit(ResourceState.success(data.copyWith(showFilters: !data.showFilters)));

  }



  void clearFilters() {

    final data = state.data;

    if (data == null) return;

    emit(

      ResourceState.success(

        data.copyWith(

          clearCategoryFilter: true,

          clearWarehouseFilter: true,

          clearStatusFilter: true,

          clearSearchQuery: true,

          warehouseProductIds: const {},

          warehouseProductSkus: const {},

          warehouseFilterLoading: false,

        ),

      ),

    );

  }



  Future<String> previewSku(String categoryId) =>

      _repository.previewNextSku(categoryId);



  Future<Product> createProduct(CreateProductInput input) async {

    try {

      final product = await _repository.createProduct(input);

      await load();

      return product;

    } on ApiException {

      rethrow;

    }

  }



  Future<Product> updateProduct(String id, UpdateProductInput input) async {

    try {

      final product = await _repository.updateProduct(id, input);

      await load();

      return product;

    } on ApiException {

      rethrow;

    }

  }



  Future<void> deleteProduct(String id) async {

    await _repository.deleteProduct(id);

    await load();

  }



  Future<ProductCategory> createCategory(String name) async {

    final category = await _repository.createCategory(name);

    final data = state.data;

    if (data != null) {

      final updated = [...data.categories, category]

        ..sort((a, b) => a.name.compareTo(b.name));

      emit(

        ResourceState.success(

          data.copyWith(categories: updated, clearCategoriesError: true),

        ),

      );

    }

    return category;

  }



  Future<void> refresh() => load();

}

