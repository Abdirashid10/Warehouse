import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/repositories/products_repository.dart';

class ProductsListState {
  const ProductsListState({
    required this.products,
    this.searchQuery = '',
    this.categoryFilter,
  });

  final List<Product> products;
  final String searchQuery;
  final String? categoryFilter;

  /// Client-side filter — same as web (name, SKU, category).
  List<Product> get filtered {
    var list = products;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q) ||
                (p.category ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    if (categoryFilter != null && categoryFilter!.isNotEmpty) {
      list = list.where((p) => p.category == categoryFilter).toList();
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<String> get categories =>
      products
          .map((p) => p.category)
          .whereType<String>()
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  ProductsListState copyWith({
    List<Product>? products,
    String? searchQuery,
    String? categoryFilter,
    bool clearCategoryFilter = false,
  }) {
    return ProductsListState(
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter:
          clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
    );
  }
}

class ProductsListCubit extends Cubit<ResourceState<ProductsListState>> {
  ProductsListCubit(this._repository) : super(const ResourceState.initial());

  final ProductsRepository _repository;

  /// Load full catalog once — web loads all products then filters in the browser.
  Future<void> load() async {
    final current = state.data;
    emit(ResourceState.loading(data: current));
    try {
      final products = await _repository.getProducts();
      emit(
        ResourceState.success(
          (current ?? const ProductsListState(products: [])).copyWith(
            products: products,
          ),
        ),
      );
    } on ApiException catch (e) {
      emit(ResourceState.failure(
        ErrorMessageMapper.fromApiException(e),
        data: current,
      ));
    } catch (_) {
      emit(ResourceState.failure('Failed to load products', data: current));
    }
  }

  void setSearch(String query) {
    final data = state.data;
    if (data == null) return;
    emit(ResourceState.success(data.copyWith(searchQuery: query)));
  }

  void setCategoryFilter(String? category) {
    final data = state.data;
    if (data == null) return;
    emit(
      ResourceState.success(
        data.copyWith(
          categoryFilter: category,
          clearCategoryFilter: category == null,
        ),
      ),
    );
  }

  Future<void> refresh() => load();
}
