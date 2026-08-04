import 'package:equatable/equatable.dart';

class ValuationReport extends Equatable {
  const ValuationReport({
    required this.totalUnits,
    required this.inventoryLines,
    required this.productCount,
    required this.costValue,
    required this.retailValue,
    required this.estimatedProfit,
    this.generatedAt,
  });

  final num totalUnits;
  final int inventoryLines;
  final int productCount;
  final num costValue;
  final num retailValue;
  final num estimatedProfit;
  final DateTime? generatedAt;

  @override
  List<Object?> get props => [
        totalUnits,
        inventoryLines,
        productCount,
        costValue,
        retailValue,
        estimatedProfit,
        generatedAt,
      ];
}

class InventoryAuditSummary extends Equatable {
  const InventoryAuditSummary({
    required this.totalUnits,
    required this.costValue,
    required this.retailValue,
    required this.lineCount,
    required this.warehouseCount,
    this.generatedAt,
  });

  final num totalUnits;
  final num costValue;
  final num retailValue;
  final int lineCount;
  final int warehouseCount;
  final DateTime? generatedAt;

  @override
  List<Object?> get props =>
      [totalUnits, costValue, retailValue, lineCount, warehouseCount, generatedAt];
}

class WmsReportsData extends Equatable {
  const WmsReportsData({
    required this.valuation,
    required this.auditSummary,
  });

  final ValuationReport valuation;
  final InventoryAuditSummary auditSummary;

  @override
  List<Object?> get props => [valuation, auditSummary];
}
