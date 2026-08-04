import 'package:logisticsmobile/features/products/data/datasources/products_remote_data_source.dart';
import 'package:logisticsmobile/features/products/data/mappers/product_mapper.dart';
import 'package:logisticsmobile/features/products/domain/entities/create_product_input.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/entities/product_category.dart';
import 'package:logisticsmobile/features/products/domain/entities/products_catalog.dart';
import 'package:logisticsmobile/features/products/domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl(this._remote);

  final ProductsRemoteDataSource _remote;

  @override
  Future<ProductsCatalog> getCatalog({String? query}) async {
    final json = await _remote.fetchCatalog(query: query);
    return ProductMapper.catalogFromJson(json);
  }

  @override
  Future<List<Product>> getProducts({String? query}) async {
    final catalog = await getCatalog(query: query);
    return catalog.products;
  }

  @override
  Future<List<ProductCategory>> getCategories() => _remote.fetchCategories();

  @override
  Future<String> previewNextSku(String categoryId) =>
      _remote.previewNextSku(categoryId);

  @override
  Future<Product> createProduct(CreateProductInput input) async {
    final json = await _remote.createProduct(input);
    return ProductMapper.fromJson(json);
  }

  @override
  Future<Product> updateProduct(String id, UpdateProductInput input) async {
    final json = await _remote.updateProduct(id, input);
    return ProductMapper.fromJson(json);
  }

  @override
  Future<ProductCategory> createCategory(String name) async {
    return _remote.createCategory(name);
  }

  @override
  Future<void> deleteProduct(String id) => _remote.deleteProduct(id);
}
