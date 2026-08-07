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

  /// Zeroed report used when the reports endpoint is unreachable or the caller
  /// lacks the Supervisor role it requires, so the rest of the analytics screen
  /// can still render.
  static const empty = WmsReportsData(
    valuation: ValuationReport(
      totalUnits: 0,
      inventoryLines: 0,
      productCount: 0,
      costValue: 0,
      retailValue: 0,
      estimatedProfit: 0,
    ),
    auditSummary: InventoryAuditSummary(
      totalUnits: 0,
      costValue: 0,
      retailValue: 0,
      lineCount: 0,
      warehouseCount: 0,
    ),
  );

  final ValuationReport valuation;
  final InventoryAuditSummary auditSummary;

  /// True when nothing was returned — lets the UI show an empty state rather
  /// than a wall of zeroes.
  bool get isEmpty =>
      valuation.totalUnits == 0 &&
      valuation.productCount == 0 &&
      auditSummary.lineCount == 0;

  @override
  List<Object?> get props => [valuation, auditSummary];
}
