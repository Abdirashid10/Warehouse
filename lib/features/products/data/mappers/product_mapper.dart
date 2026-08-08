import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/entities/product_category.dart';
import 'package:logisticsmobile/features/products/domain/entities/products_catalog.dart';
import 'package:logisticsmobile/features/products/domain/entities/products_summary.dart';

abstract final class ProductMapper {
  static Product fromJson(Map<String, dynamic> json) {
    final categoryObj = json['category'];
    String? categoryName;
    String? categoryId;
    if (categoryObj is Map) {
      categoryName = categoryObj['name']?.toString();
      categoryId = categoryObj['id']?.toString();
    }
    categoryId ??= json['category_id']?.toString() ?? json['categoryId']?.toString();
    categoryName ??= json['categoryName']?.toString();

    return Product(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      description: json['description']?.toString(),
      category: categoryName,
      categoryId: categoryId,
      unitCost: _num(json['unit_cost'] ?? json['unitCost']),
      unitPrice: _num(json['unit_price'] ?? json['unitPrice']),
      minStockThreshold:
          _num(json['min_stock_threshold'] ?? json['minStockThreshold']),
      barcode: json['barcode']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      totalStock: _num(json['total_stock'] ?? json['totalStock']),
      warehouseCount: _int(json['warehouse_count'] ?? json['warehouseCount']),
      earliestExpiry: DateTime.tryParse(
        (json['earliest_expiry'] ?? json['earliestExpiry'] ?? '').toString(),
      ),
      updatedAt: DateTime.tryParse(
        (json['updated_at'] ?? json['updatedAt'] ?? '').toString(),
      ),
    );
  }

  static ProductsCatalog catalogFromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    final products = <Product>[];
    if (rawProducts is List) {
      for (final item in rawProducts) {
        if (item is Map<String, dynamic>) {
          products.add(fromJson(item));
        } else if (item is Map) {
          products.add(fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final summaryRaw = json['summary'];
    final summary = summaryRaw is Map
        ? ProductsSummary(
            total: _int(summaryRaw['total']) ?? products.length,
            categories: _int(summaryRaw['categories']) ?? 0,
            lowStock: _int(summaryRaw['low_stock'] ?? summaryRaw['lowStock']) ?? 0,
            outOfStock:
                _int(summaryRaw['out_of_stock'] ?? summaryRaw['outOfStock']) ?? 0,
            expiring: _int(summaryRaw['expiring']) ?? 0,
            totalValue:
                _num(summaryRaw['total_value'] ?? summaryRaw['totalValue']) ?? 0,
          )
        : ProductsSummary(total: products.length);

    return ProductsCatalog(products: products, summary: summary);
  }

  static ProductCategory categoryFromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  static num? _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
