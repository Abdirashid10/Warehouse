import 'package:logisticsmobile/features/products/domain/entities/create_product_input.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/entities/product_category.dart';
import 'package:logisticsmobile/features/products/domain/entities/products_catalog.dart';

abstract class ProductsRepository {
  Future<ProductsCatalog> getCatalog({String? query});
  Future<List<Product>> getProducts({String? query});
  Future<List<ProductCategory>> getCategories();
  Future<String> previewNextSku(String categoryId);
  Future<Product> createProduct(CreateProductInput input);
  Future<Product> updateProduct(String id, UpdateProductInput input);
  Future<ProductCategory> createCategory(String name);
  Future<void> deleteProduct(String id);
}
