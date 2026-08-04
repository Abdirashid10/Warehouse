import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/json_list_parser.dart';
import 'package:logisticsmobile/features/products/domain/entities/create_product_input.dart';
import 'package:logisticsmobile/features/products/domain/entities/product_category.dart';

/// Products master data API — matches web ProductsPage.
class ProductsRemoteDataSource {
  ProductsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchCatalog({String? query}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.products,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'products': JsonListParser.extractMaps(data)};
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<List<ProductCategory>> fetchCategories() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.categories);
      final maps = JsonListParser.extractMaps(response.data, keys: ['categories']);
      return maps
          .map(
            (json) => ProductCategory(
              id: (json['id'] ?? json['_id'] ?? '').toString(),
              name: (json['name'] ?? '').toString(),
            ),
          )
          .where((c) => c.id.isNotEmpty && c.name.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<String> previewNextSku(String categoryId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiConstants.productsNextSku,
        queryParameters: {'category_id': categoryId},
      );
      final data = response.data;
      if (data is Map) {
        return (data['sku'] ?? '').toString();
      }
      return '';
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<Map<String, dynamic>> createProduct(CreateProductInput input) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiConstants.products,
        data: input.toJson(),
      );
      return _extractProductMap(response.data);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<Map<String, dynamic>> updateProduct(
    String id,
    UpdateProductInput input,
  ) async {
    try {
      final response = await _dio.patch<dynamic>(
        '${ApiConstants.products}/$id',
        data: input.toJson(),
      );
      return _extractProductMap(response.data);
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _dio.delete<dynamic>('${ApiConstants.products}/$id');
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Future<ProductCategory> createCategory(String name) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiConstants.categories,
        data: {'name': name.trim()},
      );
      final data = response.data;
      if (data is Map) {
        final cat = data['category'];
        if (cat is Map) {
          return ProductCategory(
            id: (cat['id'] ?? cat['_id'] ?? '').toString(),
            name: (cat['name'] ?? '').toString(),
          );
        }
      }
      throw const ApiException(message: 'Invalid category response');
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  Map<String, dynamic> _extractProductMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final product = data['product'];
      if (product is Map<String, dynamic>) return product;
      if (product is Map) return Map<String, dynamic>.from(product);
      return data;
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
