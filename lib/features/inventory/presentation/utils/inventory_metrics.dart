import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';

/// Client-side inventory metrics for enterprise UI (no API changes).
abstract final class InventoryMetrics {
  static bool isExpired(InventoryItem item) {
    final expiry = item.expiryDate;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  static int criticalCount(InventorySummary summary, int expired) =>
      summary.lowStock + summary.outOfStock + expired;

  static ({int inStock, int low, int out, int expired}) breakdownFor(
    Iterable<InventoryItem> items,
  ) {
    var inStock = 0;
    var low = 0;
    var out = 0;
    var expired = 0;
    for (final item in items) {
      if (isExpired(item)) {
        expired++;
      } else if (item.stockStatus == WmsStockStatuses.lowStock) {
        low++;
      } else if (item.stockStatus == WmsStockStatuses.outOfStock) {
        out++;
      } else {
        inStock++;
      }
    }
    return (inStock: inStock, low: low, out: out, expired: expired);
  }

  static int uniqueProductCount(Iterable<InventoryItem> items) {
    return items.map((i) => i.sku).toSet().length;
  }

  static int expiredCount(Iterable<InventoryItem> items) =>
      items.where(isExpired).length;

  static int expiringWithinDays(
    Iterable<InventoryItem> items, {
    required int days,
  }) {
    final now = DateTime.now();
    final until = now.add(Duration(days: days));
    return items.where((item) {
      final expiry = item.expiryDate;
      if (expiry == null) return false;
      if (!expiry.isAfter(now)) return false;
      return !expiry.isAfter(until);
    }).length;
  }

  static int safeCount(Iterable<InventoryItem> items) {
    final horizon = DateTime.now().add(const Duration(days: 30));
    return items.where((item) {
      if (isExpired(item)) return false;
      final expiry = item.expiryDate;
      if (expiry != null && expiry.isBefore(horizon)) return false;
      return item.stockStatus == WmsStockStatuses.inStock;
    }).length;
  }

  static String batchLabel(InventoryItem item) {
    final batch = item.batchNumber?.trim();
    if (batch != null && batch.isNotEmpty) return batch;
    if (item.sku.isNotEmpty) {
      final prefix = item.sku.split('-').first;
      final year = item.expiryDate?.year ?? DateTime.now().year;
      return '$prefix-$year-001';
    }
    return '—';
  }
}
