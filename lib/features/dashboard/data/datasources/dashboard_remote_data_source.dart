import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/errors/api_exception.dart';
import 'package:logisticsmobile/core/errors/error_message_mapper.dart';
import 'package:logisticsmobile/core/network/api_constants.dart';
import 'package:logisticsmobile/core/network/json_list_parser.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/staff_dashboard_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/dashboard_enterprise_widgets.dart';
class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._dio);

  final Dio _dio;

  /// GET /api/dashboard/stats
  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.dashboardStats);
      final map = JsonListParser.extractMap(response.data);
      return map ?? {};
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  /// GET /api/dashboard/widgets
  Future<Map<String, dynamic>> fetchWidgets() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.dashboardWidgets);
      final map = JsonListParser.extractMap(response.data);
      return map ?? {};
    } on DioException catch (e) {
      if (e.error is ApiException) rethrow;
      throw ApiException(message: ErrorMessageMapper.fromDioException(e));
    }
  }

  DashboardAlerts parseAlerts(Map<String, dynamic> widgets) {
    final alerts = widgets['alerts'];
    if (alerts is! Map<String, dynamic>) {
      return const DashboardAlerts();
    }
    return DashboardAlerts(
      lowStockCount: (alerts['lowStockCount'] ?? alerts['low_stock'] ?? 0) as int,
      outOfStockCount:
          (alerts['outOfStockCount'] ?? alerts['out_of_stock'] ?? 0) as int,
      expiredCount: (alerts['expiredCount'] ?? alerts['expired'] ?? 0) as int,
      expiringSoonCount:
          (alerts['expiringSoonCount'] ?? alerts['expiring_soon'] ?? 0) as int,
    );
  }

  List<WarehouseStat> parseWarehouseStats(Map<String, dynamic> widgets) {
    final raw = widgets['warehouseStats'] ?? widgets['warehouse_stats'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map((w) {
      return WarehouseStat(
        id: (w['id'] ?? w['_id'] ?? '').toString(),
        name: (w['name'] ?? '').toString(),
        totalUnits: w['totalUnits'] ?? w['total_units'] ?? 0,
        utilization: (w['utilization'] ?? 0) as int,
        location: (w['location'] ?? w['address'])?.toString(),
        productCount: _asInt(w['productCount'] ?? w['product_count'] ?? w['lineCount']),
      );
    }).toList();
  }

  List<DashboardInsight> parseInsights(Map<String, dynamic> widgets) {
    final raw = widgets['insights'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map((i) {
      return DashboardInsight(
        message: (i['message'] ?? '').toString(),
        severity: (i['severity'] ?? 'info').toString(),
      );
    }).toList();
  }

  /// Backend-provided order trend series from `/dashboard/stats` or `/dashboard/widgets`.
  DashboardChartTimeSeries? parseOrderTrendSeries(Map<String, dynamic> source) {
    return _parseTrendSeries(
      source,
      keys: const [
        'orderTrend',
        'order_trend',
        'orderCreationTrend',
        'order_creation_trend',
      ],
      defaultLineLabel: 'Orders',
      defaultLineColor: AppColors.primary,
    );
  }

  /// Backend-provided movement trend series from `/dashboard/stats` or `/dashboard/widgets`.
  DashboardChartTimeSeries? parseMovementTrendSeries(Map<String, dynamic> source) {
    final dual = _parseDualMovementTrend(source);
    if (dual != null) return dual;

    return _parseTrendSeries(
      source,
      keys: const [
        'movementTrend',
        'movement_trend',
        'stockMovementTrend',
        'stock_movement_trend',
      ],
      defaultLineLabel: 'Movements',
      defaultLineColor: AppColors.info,
    );
  }

  DashboardChartTimeSeries? _parseDualMovementTrend(Map<String, dynamic> source) {
    final raw = _firstMap(source, const [
      'movementTrend',
      'movement_trend',
      'stockMovementTrend',
      'stock_movement_trend',
    ]);
    if (raw == null) return null;

    final labels = _parseLabels(raw);
    final inboundValues = _parseValues(raw, const [
      'inbound',
      'inboundValues',
      'inbound_values',
      'in',
    ]);
    final outboundValues = _parseValues(raw, const [
      'outbound',
      'outboundValues',
      'outbound_values',
      'out',
    ]);

    if (labels.isEmpty || inboundValues.isEmpty && outboundValues.isEmpty) {
      return null;
    }

    return DashboardChartTimeSeries(
      labels: labels,
      lines: [
        if (inboundValues.isNotEmpty)
          DashboardChartLine(
            label: 'Inbound',
            color: AppColors.success,
            values: inboundValues,
          ),
        if (outboundValues.isNotEmpty)
          DashboardChartLine(
            label: 'Outbound',
            color: const Color(0xFFC2410C),
            values: outboundValues,
          ),
      ],
    );
  }

  DashboardChartTimeSeries? _parseTrendSeries(
    Map<String, dynamic> source, {
    required List<String> keys,
    required String defaultLineLabel,
    required Color defaultLineColor,
  }) {
    final raw = _firstMap(source, keys);
    if (raw == null) return null;

    final labels = _parseLabels(raw);
    final values = _parseValues(raw, const ['values', 'data', 'counts', 'series']);
    if (labels.isEmpty || values.isEmpty) return null;

    return DashboardChartTimeSeries(
      labels: labels,
      lines: [
        DashboardChartLine(
          label: (raw['label'] ?? defaultLineLabel).toString(),
          color: defaultLineColor,
          values: values,
        ),
      ],
    );
  }

  Map<String, dynamic>? _firstMap(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is Map<String, dynamic>) return value;
    }
    return null;
  }

  List<String> _parseLabels(Map<String, dynamic> raw) {
    final labelsRaw = raw['labels'] ?? raw['days'] ?? raw['dates'];
    if (labelsRaw is! List) return [];
    return labelsRaw.map((e) => e.toString()).toList();
  }

  List<double> _parseValues(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final valuesRaw = raw[key];
      if (valuesRaw is List) {
        return valuesRaw
            .map((e) => e is num ? e.toDouble() : double.tryParse('$e') ?? 0)
            .toList();
      }
    }
    return const [];
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
