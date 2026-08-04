class CreateProductInput {
  const CreateProductInput({
    required this.name,
    required this.categoryId,
    required this.unitCost,
    required this.unitPrice,
    this.description = '',
    this.barcode = '',
    this.minStockThreshold = 0,
    this.imageUrl = '',
  });

  final String name;
  final String categoryId;
  final num unitCost;
  final num unitPrice;
  final String description;
  final String barcode;
  final num minStockThreshold;
  final String imageUrl;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category_id': categoryId,
        'unit_cost': unitCost,
        'unit_price': unitPrice,
        'description': description,
        'barcode': barcode,
        'min_stock_threshold': minStockThreshold,
        if (imageUrl.isNotEmpty) 'image_url': imageUrl,
      };
}

class UpdateProductInput {
  const UpdateProductInput({
    required this.name,
    required this.categoryId,
    required this.unitCost,
    required this.unitPrice,
    this.description = '',
    this.barcode = '',
    this.minStockThreshold = 0,
    this.imageUrl = '',
  });

  final String name;
  final String categoryId;
  final num unitCost;
  final num unitPrice;
  final String description;
  final String barcode;
  final num minStockThreshold;
  final String imageUrl;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category_id': categoryId,
        'unit_cost': unitCost,
        'unit_price': unitPrice,
        'description': description,
        'barcode': barcode,
        'min_stock_threshold': minStockThreshold,
        'image_url': imageUrl,
      };
}
