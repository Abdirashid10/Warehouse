import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/products/domain/entities/product.dart';
import 'package:logisticsmobile/features/products/domain/entities/product_category.dart';
import 'package:logisticsmobile/features/products/domain/entities/products_summary.dart';
import 'package:logisticsmobile/features/products/presentation/widgets/products_enterprise_widgets.dart';
import 'package:logisticsmobile/widgets/wms/wms_metric_pill.dart';

/// Layout and contrast contract for the redesigned Product List screen.
void main() {
  const widths = <double>[320, 360, 375, 393, 412, 430, 480];
  const textScales = <double>[1.0, 1.2, 1.3];

  Product product({
    String name = 'Wireless Optical Mouse Pro Ergonomic Edition',
    String sku = 'SKU-PRD-000241-A',
    String? category = 'Computer Peripherals & Accessories',
    num stock = 128456,
    num threshold = 50,
    DateTime? expiry,
  }) {
    return Product(
      id: sku,
      name: name,
      sku: sku,
      category: category,
      unitPrice: 1249.99,
      totalStock: stock,
      warehouseCount: 12,
      minStockThreshold: threshold,
      earliestExpiry: expiry,
      updatedAt: DateTime(2026, 8, 1),
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

    await tester.binding.setSurfaceSize(Size(width, 1000));
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

  Widget card(Product p) => ProductsMobileCard(
        product: p,
        canManage: true,
        isAdmin: true,
        onView: () {},
        onEdit: () {},
        onStockHistory: () {},
        onTransfer: () {},
        onDelete: () {},
      );

  group('ProductsMobileCard', () {
    for (final width in widths) {
      for (final scale in textScales) {
        testWidgets('no overflow at ${width.toInt()}dp @ ${scale}x text',
            (tester) async {
          final overflows = await pump(
            tester,
            width: width,
            textScale: scale,
            child: Column(
              children: [
                card(product()),
                const SizedBox(height: 8),
                card(product(name: 'Pen', sku: 'S1', category: null, stock: 0)),
              ],
            ),
          );
          expect(overflows, isEmpty, reason: overflows.join('\n'));
        });
      }
    }

    testWidgets('card is far shorter than the stacked layout it replaced',
        (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: card(product()),
      );
      final height = tester.getSize(find.byType(ProductsMobileCard)).height;
      // The old card ran past 300dp once the stat boxes and five action
      // chips were stacked. Anything approaching that is a regression.
      expect(height, lessThan(170));
    });

    testWidgets('actions collapse into a single overflow menu', (tester) async {
      await pump(
        tester,
        width: 360,
        textScale: 1.0,
        child: card(product()),
      );

      expect(find.byType(PopupMenuButton<VoidCallback>), findsOneWidget);
      // None of the action labels should occupy card space until opened.
      expect(find.text('View details'), findsNothing);
      expect(find.text('Transfer stock'), findsNothing);

      await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
      await tester.pumpAndSettle();

      expect(find.text('View details'), findsOneWidget);
      expect(find.text('Edit product'), findsOneWidget);
      expect(find.text('Transfer stock'), findsOneWidget);
      expect(find.text('Stock history'), findsOneWidget);
      expect(find.text('Delete product'), findsOneWidget);
    });

    testWidgets('non-managers only get view and history', (tester) async {
      await pump(
        tester,
        width: 360,
        textScale: 1.0,
        child: ProductsMobileCard(
          product: product(),
          canManage: false,
          isAdmin: false,
          onView: () {},
          onEdit: () {},
          onStockHistory: () {},
          onTransfer: () {},
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
      await tester.pumpAndSettle();

      expect(find.text('View details'), findsOneWidget);
      expect(find.text('Stock history'), findsOneWidget);
      expect(find.text('Edit product'), findsNothing);
      expect(find.text('Transfer stock'), findsNothing);
      expect(find.text('Delete product'), findsNothing);
    });

    testWidgets('name and SKU line stay single-line', (tester) async {
      await pump(
        tester,
        width: 360,
        textScale: 1.0,
        child: card(product()),
      );

      final name = tester.widget<Text>(
        find.text('Wireless Optical Mouse Pro Ergonomic Edition'),
      );
      expect(name.maxLines, 1);
      expect(name.overflow, TextOverflow.ellipsis);

      final subtitle = tester.widget<Text>(find.text(
        'SKU-PRD-000241-A · Computer Peripherals & Accessories',
      ));
      expect(subtitle.maxLines, 1);
      expect(subtitle.overflow, TextOverflow.ellipsis);
    });

    testWidgets('renders in dark theme without overflow', (tester) async {
      final overflows = await pump(
        tester,
        width: 360,
        textScale: 1.2,
        theme: AppTheme.dark,
        child: card(product()),
      );
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });
  });

  group('ProductEnterpriseStatusBadge', () {
    /// The old implementation hardcoded these near-black dark-theme fills and
    /// used them on the light theme too.
    const legacyDarkFills = <Color>[
      Color(0xFF14532D),
      Color(0xFF78350F),
      Color(0xFF7F1D1D),
      Color(0xFF334155),
    ];

    for (final status in [
      'In Stock',
      'Low Stock',
      'Out Of Stock',
      'Expired',
      'No Inventory',
    ]) {
      testWidgets('$status does not use a dark fill on the light theme',
          (tester) async {
        await pump(
          tester,
          width: 360,
          textScale: 1.0,
          child: ProductEnterpriseStatusBadge(label: status),
        );

        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(ProductEnterpriseStatusBadge),
                matching: find.byType(Container),
              )
              .first,
        );
        final fill = (container.decoration! as BoxDecoration).color!;
        expect(
          legacyDarkFills,
          isNot(contains(fill)),
          reason: '$status still renders the dark-theme swatch',
        );
      });
    }

    testWidgets('label stays legible and single-line', (tester) async {
      await pump(
        tester,
        width: 320,
        textScale: 1.3,
        child: const ProductEnterpriseStatusBadge(
          label: 'Out Of Stock',
          dense: true,
        ),
      );
      final text = tester.widget<Text>(find.text('Out Of Stock'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });

  group('Search & filter header', () {
    Widget searchSection({
      String? categoryFilterId,
      String? warehouseFilterId,
    }) =>
        ProductsMobileSearchSection(
          searchController: TextEditingController(),
          onSearch: (_) {},
          categories: const [
            ProductCategory(id: 'c1', name: 'Drink'),
            ProductCategory(id: 'c2', name: 'Electronic'),
            ProductCategory(id: 'c3', name: 'Food'),
            ProductCategory(id: 'c4', name: 'mobile'),
            ProductCategory(id: 'c5', name: 'Sports'),
            ProductCategory(id: 'c6', name: 'Home & Garden Supplies'),
          ],
          warehouses: const [
            WarehouseOption(id: 'w1', name: 'Central Distribution Center'),
            WarehouseOption(id: 'w2', name: 'North Warehouse'),
            WarehouseOption(id: 'w3', name: 'South Depot'),
          ],
          categoryFilterId: categoryFilterId,
          warehouseFilterId: warehouseFilterId,
          warehouseFilterLoading: false,
          onCategory: (_) {},
          onWarehouse: (_) {},
        );

    for (final width in [320.0, 360.0, 393.0]) {
      testWidgets('single row with no overflow at ${width.toInt()}dp',
          (tester) async {
        final overflows = await pump(
          tester,
          width: width,
          textScale: 1.0,
          child: searchSection(),
        );
        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }

    testWidgets('unfiltered header costs one control row only', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: searchSection(),
      );
      final height =
          tester.getSize(find.byType(ProductsMobileSearchSection)).height;
      // Search + filter button on one line. The two chip strips it replaced
      // cost ~76dp on top of the field even when nothing was filtered.
      expect(height, lessThan(60));
    });

    testWidgets('active filters surface as removable chips', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: searchSection(categoryFilterId: 'c2', warehouseFilterId: 'w2'),
      );

      expect(find.text('Electronic'), findsOneWidget);
      expect(find.text('North Warehouse'), findsOneWidget);
      // The count badge on the filter button reflects both.
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('filter button opens a sheet holding both filter groups',
        (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: searchSection(),
      );

      // Options live in the sheet, not on the page.
      expect(find.text('All categories'), findsNothing);

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ProductsFilterSheet), findsOneWidget);
      expect(find.text('All categories'), findsOneWidget);
      expect(find.text('All warehouses'), findsOneWidget);
      expect(find.text('Electronic'), findsOneWidget);
      expect(find.text('North Warehouse'), findsOneWidget);
    });
  });

  group('ProductsMobileKpiGrid', () {
    Widget kpiGrid() => const ProductsMobileKpiGrid(
          summary: ProductsSummary(
            total: 1284,
            categories: 6,
            lowStock: 37,
            outOfStock: 12,
            expiring: 4,
            totalValue: 9876543.21,
          ),
        );

    for (final width in [320.0, 360.0, 393.0, 430.0]) {
      testWidgets('no overflow at ${width.toInt()}dp', (tester) async {
        final overflows = await pump(
          tester,
          width: width,
          textScale: 1.3,
          child: kpiGrid(),
        );
        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }

    testWidgets('all six metrics occupy a single strip row', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: kpiGrid(),
      );

      final height = tester.getSize(find.byType(ProductsMobileKpiGrid)).height;
      // Six tall cards in a 2-column grid previously ran three rows (~500dp).
      expect(height, WmsMetricPillBar.height);

      // The strip is a lazy horizontal list, so only the pills currently on
      // screen are built — that laziness is the point.
      expect(find.byType(WmsMetricPill), findsWidgets);
      expect(
        tester.widget<WmsMetricPillBar>(find.byType(WmsMetricPillBar)).metrics,
        hasLength(6),
      );
    });

    testWidgets('every metric is reachable by scrolling', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: kpiGrid(),
      );

      final strip = find.byType(Scrollable).first;
      for (final label in [
        'Active Products',
        'Categories',
        'Low Stock',
        'Out Of Stock',
        'Expiring',
        'Catalog Value',
      ]) {
        await tester.scrollUntilVisible(
          find.text(label),
          120,
          scrollable: strip,
        );
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
    });
  });
}
