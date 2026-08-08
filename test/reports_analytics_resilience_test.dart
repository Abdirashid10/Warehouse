import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/features/reports/domain/entities/wms_reports_data.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_analytics_cubit.dart';
import 'package:logisticsmobile/features/reports/presentation/cubit/reports_sample_data.dart';

/// The Reports screen aggregates eight endpoints that do **not** share a
/// permission level — `/api/users` is Admin-only, reports and inventory
/// tracking need Supervisor — yet every role can open the screen. These tests
/// pin the resulting behaviour so a single 403 can never blank the page again.
void main() {
  group('WmsReportsData.empty', () {
    test('is a usable zeroed fallback', () {
      const empty = WmsReportsData.empty;
      expect(empty.valuation.totalUnits, 0);
      expect(empty.valuation.productCount, 0);
      expect(empty.auditSummary.lineCount, 0);
      expect(empty.isEmpty, isTrue);
    });

    test('a populated report is not reported empty', () {
      final data = ReportsSampleData.build().reports;
      expect(data.isEmpty, isFalse);
    });
  });

  group('ReportsAnalyticsBundle', () {
    test('defaults to complete and live', () {
      final bundle = ReportsSampleData.build();
      // Sample bundles are explicitly flagged.
      expect(bundle.isSampleData, isTrue);
      expect(bundle.isPartial, isFalse);
    });

    test('records which sources were unavailable', () {
      final base = ReportsSampleData.build();
      final partial = ReportsAnalyticsBundle(
        reports: base.reports,
        products: base.products,
        inventoryTracking: base.inventoryTracking,
        warehouses: base.warehouses,
        orders: base.orders,
        users: const [],
        tasks: base.tasks,
        movements: base.movements,
        unavailableSources: const ['Users'],
      );

      expect(partial.isPartial, isTrue);
      expect(partial.unavailableSources, ['Users']);
      // Everything else still carries real content.
      expect(partial.products, isNotEmpty);
      expect(partial.tasks, isNotEmpty);
      expect(partial.isSampleData, isFalse);
    });

    test('a users-only failure still leaves the screen with data', () {
      final base = ReportsSampleData.build();
      final partial = ReportsAnalyticsBundle(
        reports: base.reports,
        products: base.products,
        inventoryTracking: base.inventoryTracking,
        warehouses: base.warehouses,
        orders: base.orders,
        users: const [],
        tasks: base.tasks,
        movements: base.movements,
        unavailableSources: const ['Users'],
      );

      final computed = AnalyticsComputer.compute(
        bundle: partial,
        preset: AnalyticsDatePreset.year,
        customRange: null,
      );

      // This is the supervisor case that previously produced
      // "Failed to load analytics data".
      expect(computed.hasAnyData, isTrue);
      expect(partial.activeUsersCount, 0);
    });
  });

  group('ReportsSampleData', () {
    test('is flagged so the UI can label it', () {
      expect(ReportsSampleData.build().isSampleData, isTrue);
    });

    test('populates every chart series the screen renders', () {
      final bundle = ReportsSampleData.build();
      expect(bundle.products, isNotEmpty);
      expect(bundle.inventoryTracking.items, isNotEmpty);
      expect(bundle.warehouses, isNotEmpty);
      expect(bundle.orders.orders, isNotEmpty);
      expect(bundle.tasks, isNotEmpty);
      expect(bundle.movements.movements, isNotEmpty);
    });

    test('every identifier is namespaced so it cannot be mistaken for live '
        'records', () {
      final bundle = ReportsSampleData.build();
      for (final p in bundle.products) {
        expect(p.id, startsWith('sample-'));
        expect(p.sku, startsWith('SAMPLE-'));
      }
      for (final o in bundle.orders.orders) {
        expect(o.orderNumber, startsWith('SAMPLE-'));
      }
    });

    test('falls inside the last year so date filters still show it', () {
      final bundle = ReportsSampleData.build();
      final computed = AnalyticsComputer.compute(
        bundle: bundle,
        preset: AnalyticsDatePreset.year,
        customRange: null,
      );
      expect(computed.filteredOrders, isNotEmpty);
      expect(computed.filteredMovements, isNotEmpty);
      expect(computed.hasAnyData, isTrue);
    });
  });
}
