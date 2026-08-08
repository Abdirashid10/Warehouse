import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:logisticsmobile/features/inventory/presentation/widgets/inventory_mobile_widgets.dart';

/// Layout contract for the redesigned Inventory Tracking surfaces.
///
/// The old product card stacked eleven labelled fields with two-line values,
/// which wrapped raggedly on narrow screens. These tests pin the replacement
/// to single-line, overflow-free behaviour across the supported width range
/// and accessibility text scales.
void main() {
  const widths = <double>[320, 360, 375, 393, 412, 430, 480];
  const textScales = <double>[1.0, 1.2, 1.3];

  InventoryItem item({
    String name = 'Premium Stainless Steel Insulated Water Bottle 1L',
    String sku = 'SKU-PRD-000241-A',
    String warehouse = 'Central Distribution Warehouse North',
    num qty = 128456,
    String status = 'In Stock',
    DateTime? expiry,
  }) {
    return InventoryItem(
      id: 'id-$sku',
      productName: name,
      sku: sku,
      warehouseName: warehouse,
      quantity: qty,
      stockStatus: status,
      minThreshold: 20,
      expiryDate: expiry,
    );
  }

  Future<List<String>> pump(
    WidgetTester tester, {
    required double width,
    required double textScale,
    required Widget child,
    ThemeData? theme,
  }) async {
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed')) {
        overflows.add(message.split('\n').first);
      } else if (!message.contains('google_fonts')) {
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);

    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return overflows;
  }

  group('InventoryProductTile', () {
    for (final width in widths) {
      for (final scale in textScales) {
        testWidgets(
          'no overflow at ${width.toInt()}dp @ ${scale}x text',
          (tester) async {
            final overflows = await pump(
              tester,
              width: width,
              textScale: scale,
              child: Column(
                children: [
                  InventoryProductTile(
                    item: item(),
                    availableQuantity: 98234,
                    reservedQuantity: 30222,
                    lastUpdated: DateTime(2026, 8, 1),
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  InventoryProductTile(
                    item: item(
                      name: 'Pen',
                      sku: 'S1',
                      warehouse: 'W1',
                      qty: 0,
                      status: 'Out of Stock',
                      expiry: DateTime(2020, 1, 1),
                    ),
                    availableQuantity: 0,
                    reservedQuantity: 0,
                    lastUpdated: null,
                    onTap: () {},
                  ),
                ],
              ),
            );
            expect(overflows, isEmpty, reason: overflows.join('\n'));
          },
        );
      }
    }

    testWidgets('product name and location stay on one line each',
        (tester) async {
      await pump(
        tester,
        width: 360,
        textScale: 1.0,
        child: InventoryProductTile(
          item: item(),
          availableQuantity: 10,
          reservedQuantity: 5,
          lastUpdated: DateTime(2026, 8, 1),
          onTap: () {},
        ),
      );

      final name = tester.widget<Text>(find.text(
        'Premium Stainless Steel Insulated Water Bottle 1L',
      ));
      expect(name.maxLines, 1);
      expect(name.overflow, TextOverflow.ellipsis);

      final subtitle = tester.widget<Text>(find.text(
        'SKU-PRD-000241-A · Central Distribution Warehouse North',
      ));
      expect(subtitle.maxLines, 1);
      expect(subtitle.overflow, TextOverflow.ellipsis);
    });

    testWidgets('tile is far shorter than the card it replaced',
        (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: InventoryProductTile(
          item: item(),
          availableQuantity: 10,
          reservedQuantity: 5,
          lastUpdated: DateTime(2026, 8, 1),
          onTap: () {},
        ),
      );

      final height =
          tester.getSize(find.byType(InventoryProductTile)).height;
      // The previous card ran ~380dp; anything near that is a regression.
      expect(height, lessThan(140));
    });

    testWidgets('renders in dark theme without overflow', (tester) async {
      final overflows = await pump(
        tester,
        width: 360,
        textScale: 1.2,
        theme: AppTheme.dark,
        child: InventoryProductTile(
          item: item(),
          availableQuantity: 10,
          reservedQuantity: 5,
          lastUpdated: DateTime(2026, 8, 1),
          onTap: () {},
        ),
      );
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });
  });

  group('InventoryResultsBar', () {
    for (final width in [320.0, 360.0, 430.0]) {
      testWidgets('no overflow at ${width.toInt()}dp', (tester) async {
        final overflows = await pump(
          tester,
          width: width,
          textScale: 1.3,
          child: InventoryResultsBar(
            count: 1284,
            sortField: InventorySortField.lastUpdated,
            sortAscending: false,
            onSort: (_) {},
          ),
        );
        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }

    testWidgets('pluralises the result count', (tester) async {
      await pump(
        tester,
        width: 360,
        textScale: 1.0,
        child: InventoryResultsBar(
          count: 1,
          sortField: InventorySortField.name,
          sortAscending: true,
          onSort: (_) {},
        ),
      );
      expect(find.text('1 product'), findsOneWidget);
    });
  });
}
