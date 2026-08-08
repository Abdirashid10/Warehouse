import 'package:dio/dio.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/features/reports/domain/entities/wms_reports_data.dart';

class ReportsRemoteDataSource {
  ReportsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<WmsReportsData> fetchReports() async {
    try {
      final results = await Future.wait([
        _dio.get<dynamic>(ApiConstants.reportsValuation),
        _dio.get<dynamic>(ApiConstants.reportsInventoryAudit),
      ]);
      final valuationJson = results[0].data;
      final auditJson = results[1].data;

      return WmsReportsData(
        valuation: _mapValuation(valuationJson),
        auditSummary: _mapAuditSummary(auditJson),
      );
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  ValuationReport _mapValuation(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const ValuationReport(
        totalUnits: 0,
        inventoryLines: 0,
        productCount: 0,
        costValue: 0,
        retailValue: 0,
        estimatedProfit: 0,
      );
    }
    final v = data['valuation'];
    final map = v is Map<String, dynamic> ? v : data;
    return ValuationReport(
      totalUnits: map['total_units'] ?? map['totalUnits'] ?? 0,
      inventoryLines:
          (map['inventory_lines'] ?? map['inventoryLines'] ?? 0) as int,
      productCount: (map['product_count'] ?? map['productCount'] ?? 0) as int,
      costValue: map['cost_value'] ?? map['costValue'] ?? 0,
      retailValue: map['retail_value'] ?? map['retailValue'] ?? 0,
      estimatedProfit: map['estimated_profit'] ?? map['estimatedProfit'] ?? 0,
      generatedAt: DateTime.tryParse(
        (map['generated_at'] ?? map['generatedAt'] ?? '').toString(),
      ),
    );
  }

  InventoryAuditSummary _mapAuditSummary(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const InventoryAuditSummary(
        totalUnits: 0,
        costValue: 0,
        retailValue: 0,
        lineCount: 0,
        warehouseCount: 0,
      );
    }
    final financial = data['financial_summary'];
    final map = financial is Map<String, dynamic> ? financial : data;
    final warehouses = data['warehouse_comparison'];
    var warehouseCount = 0;
    if (warehouses is List) warehouseCount = warehouses.length;

    return InventoryAuditSummary(
      totalUnits: map['total_units'] ?? map['totalUnits'] ?? 0,
      costValue: map['cost_value'] ?? map['costValue'] ?? 0,
      retailValue: map['retail_value'] ?? map['retailValue'] ?? 0,
      lineCount: (map['inventory_lines'] ?? map['lineCount'] ?? 0) as int,
      warehouseCount: warehouseCount,
      generatedAt: DateTime.tryParse(
        (data['generated_at'] ?? data['generatedAt'] ?? '').toString(),
      ),
    );
  }
}
