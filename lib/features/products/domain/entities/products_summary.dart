import 'package:equatable/equatable.dart';

class ProductsSummary extends Equatable {
  const ProductsSummary({
    this.total = 0,
    this.categories = 0,
    this.lowStock = 0,
    this.outOfStock = 0,
    this.expiring = 0,
    this.totalValue = 0,
  });

  final int total;
  final int categories;
  final int lowStock;
  final int outOfStock;
  final int expiring;
  final num totalValue;

  @override
  List<Object?> get props =>
      [total, categories, lowStock, outOfStock, expiring, totalValue];
}
