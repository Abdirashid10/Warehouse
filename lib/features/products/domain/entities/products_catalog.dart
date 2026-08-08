import 'package:equatable/equatable.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/entities/products_summary.dart';

class ProductsCatalog extends Equatable {
  const ProductsCatalog({
    required this.products,
    required this.summary,
  });

  final List<Product> products;
  final ProductsSummary summary;

  @override
  List<Object?> get props => [products, summary];
}
