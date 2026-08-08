import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_ops_premium_theme.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_ops_premium_widgets.dart';

/// Layout and behaviour contract for the premium Stock Operations surfaces.
void main() {
  final now = DateTime.now();

  StockMovement movement({
    String type = WmsMovementTypes.transfer,
    String product = 'Premium Wireless Headphones',
    String? from = 'Madiina',
    String? to = 'Bakaaro',
    num quantity = 240,
  }) =>
      StockMovement(
        id: 'm1',
        type: type,
        productName: product,
        sku: 'ELEC-HP-001',
        quantity: quantity,
        performedBy: 'Ayaan Hassan',
        timestamp: now.subtract(const Duration(hours: 3)),
        fromLocation: from,
        toLocation: to,
      );

  const bentoMetrics = [
    StockOpsBentoMetric(
      label: "Today's Inbound",
      value: '12',
      spec: StockOpsKinds.inbound,
      accent: Color(0xFF6EE7B7),
    ),
    StockOpsBentoMetric(
      label: "Today's Outbound",
      value: '8',
      spec: StockOpsKinds.outbound,
      accent: Color(0xFFFCD34D),
    ),
    StockOpsBentoMetric(
      label: "Today's Transfers",
      value: '1,284',
      spec: StockOpsKinds.transfer,
      accent: Color(0xFF7DD3FC),
    ),
    StockOpsBentoMetric(
      label: "Today's Returns",
      value: '3',
      spec: StockOpsKinds.returned,
      accent: Color(0xFFC4B5FD),
    ),
  ];

  Future<List<String>> pump(
    WidgetTester tester, {
    required Widget child,
    double width = 393,
    double height = 1200,
    double textScale = 1.0,
    ThemeData? theme,
  }) async {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('google_fonts')) return;
      errors.add(message.split('\n').first);
    };
    addTearDown(() => FlutterError.onError = previous);

    await tester.binding.setSurfaceSize(Size(width, height));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    return errors;
  }

  group('operation taxonomy', () {
    test('backend movement types map onto operation kinds', () {
      expect(
        StockOpsKinds.fromType(WmsMovementTypes.inbound).kind,
        StockOpsKind.inbound,
      );
      expect(
        StockOpsKinds.fromType(WmsMovementTypes.outbound).kind,
        StockOpsKind.outbound,
      );
      expect(
        StockOpsKinds.fromType(WmsMovementTypes.transfer).kind,
        StockOpsKind.transfer,
      );
      expect(
        StockOpsKinds.fromType(WmsMovementTypes.returnType).kind,
        StockOpsKind.returned,
      );
      // Anything unrecognised is an adjustment rather than silently reading as
      // one of the four primary flows.
      expect(StockOpsKinds.fromType('SOMETHING_NEW').kind,
          StockOpsKind.adjustment);
    });

    testWidgets('each operation kind gets a distinct accent', (tester) async {
      late StockOpsPalette palette;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              palette = StockOpsPalette.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final accents = {
        for (final kind in StockOpsKind.values) palette.accentFor(kind),
      };
      expect(accents.length, StockOpsKind.values.length);
    });
  });

  group('bento grid', () {
    for (final width in const [320.0, 360.0, 393.0, 412.0]) {
      for (final scale in const [1.0, 1.3]) {
        testWidgets('hero renders clean at ${width.toInt()}dp @ ${scale}x',
            (tester) async {
          final errors = await pump(
            tester,
            width: width,
            textScale: scale,
            child: const SingleChildScrollView(
              child: StockOpsHeroBanner(
                title: 'Stock Operations',
                subtitle: 'Inbound, outbound, transfer and return workflows',
                metrics: bentoMetrics,
              ),
            ),
          );
          expect(errors, isEmpty, reason: errors.join('\n'));
        });
      }
    }

    testWidgets('shows all four operation metrics', (tester) async {
      await pump(
        tester,
        child: const SingleChildScrollView(
          child: StockOpsHeroBanner(
            title: 'Stock Operations',
            subtitle: 'Inbound, outbound, transfer and return workflows',
            metrics: bentoMetrics,
          ),
        ),
      );

      expect(find.text("Today's Inbound"), findsOneWidget);
      expect(find.text("Today's Outbound"), findsOneWidget);
      expect(find.text("Today's Transfers"), findsOneWidget);
      expect(find.text("Today's Returns"), findsOneWidget);
      expect(find.text('1,284'), findsOneWidget);
    });

    testWidgets('lays out 2x2 on a phone', (tester) async {
      await pump(
        tester,
        width: 393,
        child: const SingleChildScrollView(
          child: StockOpsBentoGrid(metrics: bentoMetrics),
        ),
      );

      final inbound = tester.getTopLeft(find.text("Today's Inbound"));
      final outbound = tester.getTopLeft(find.text("Today's Outbound"));
      final transfers = tester.getTopLeft(find.text("Today's Transfers"));

      // First two tiles share a row; the third starts the next one.
      expect(inbound.dy, outbound.dy);
      expect(transfers.dy, greaterThan(inbound.dy));
    });
  });

  group('history card', () {
    testWidgets('renders route, quantity pill and attribution', (tester) async {
      final errors = await pump(
        tester,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StockOpsHistoryCard(movement: movement()),
          ),
        ),
      );

      expect(errors, isEmpty, reason: errors.join('\n'));
      expect(find.text('Premium Wireless Headphones'), findsOneWidget);
      expect(find.text('ELEC-HP-001'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Madiina'), findsOneWidget);
      expect(find.text('Bakaaro'), findsOneWidget);
      expect(find.text('240'), findsOneWidget);
      expect(find.text('Ayaan Hassan'), findsOneWidget);
    });

    testWidgets('omits the route chip when no locations are recorded',
        (tester) async {
      await pump(
        tester,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StockOpsHistoryCard(
              movement: movement(
                type: WmsMovementTypes.inbound,
                from: null,
                to: null,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(StockOpsRouteChip), findsNothing);
      expect(find.text('Inbound'), findsOneWidget);
    });

    testWidgets('a movement with no timestamp says so', (tester) async {
      await pump(
        tester,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StockOpsHistoryCard(
              movement: StockMovement(
                id: 'm2',
                type: WmsMovementTypes.outbound,
                productName: 'Organic Milk 1L',
                sku: 'FOOD-MLK-002',
                quantity: 12,
                performedBy: '',
                timestamp: null,
              ),
            ),
          ),
        ),
      );

      expect(find.text('No timestamp'), findsOneWidget);
      // An empty operator falls back to System rather than rendering blank.
      expect(find.text('System'), findsOneWidget);
    });

    for (final width in const [320.0, 360.0, 412.0]) {
      testWidgets('card fits at ${width.toInt()}dp with a long product name',
          (tester) async {
        final errors = await pump(
          tester,
          width: width,
          textScale: 1.3,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StockOpsHistoryCard(
                movement: movement(
                  product:
                      'Premium Wireless Bluetooth Headphones with Noise Cancellation',
                  from: 'Madiina Distribution Center',
                  to: 'Bakaaro Market Warehouse',
                  quantity: 1284567,
                ),
              ),
            ),
          ),
        );
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
    }
  });

  group('alerts feed', () {
    testWidgets('a populated section lists entries with a count badge',
        (tester) async {
      final errors = await pump(
        tester,
        child: const SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: StockOpsAlertSection(
              title: 'Out of Stock',
              subtitle: 'Zero units available — fulfilment is blocked',
              icon: Icons.remove_shopping_cart_rounded,
              severity: StockAlertSeverity.critical,
              entries: [
                StockOpsAlertEntry(
                  title: 'Organic Milk 1L',
                  subtitle: 'Bakaaro',
                  trailing: '0',
                ),
                StockOpsAlertEntry(
                  title: 'Football Size 5',
                  subtitle: 'Madiina',
                  trailing: '0',
                ),
              ],
            ),
          ),
        ),
      );

      expect(errors, isEmpty, reason: errors.join('\n'));
      expect(find.text('Out of Stock'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Organic Milk 1L'), findsOneWidget);
      expect(find.text('Football Size 5'), findsOneWidget);
    });

    testWidgets('an empty section reassures instead of listing nothing',
        (tester) async {
      await pump(
        tester,
        child: const SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: StockOpsAlertSection(
              title: 'Transfer Failures',
              subtitle: 'Transfers flagged as failed in the audit trail',
              icon: Icons.sync_problem_rounded,
              severity: StockAlertSeverity.info,
              emptyMessage: 'No transfer failures in the current window.',
              entries: [],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(
        find.text('No transfer failures in the current window.'),
        findsOneWidget,
      );
    });

    testWidgets('long lists summarise the tail rather than growing unbounded',
        (tester) async {
      await pump(
        tester,
        height: 1600,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StockOpsAlertSection(
              title: 'Low Stock',
              subtitle: 'Below the reorder threshold',
              icon: Icons.trending_down_rounded,
              severity: StockAlertSeverity.warning,
              entries: [
                for (var i = 0; i < 12; i++)
                  StockOpsAlertEntry(title: 'Product $i', subtitle: 'Bakaaro'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget); // full count in the badge
      expect(find.text('Product 0'), findsOneWidget);
      expect(find.text('Product 7'), findsOneWidget);
      expect(find.text('Product 8'), findsNothing);
      expect(find.text('+4 more'), findsOneWidget);
    });
  });

  group('filters', () {
    testWidgets('search field clears through its own affordance',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];

      await pump(
        tester,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StockOpsSearchField(
            controller: controller,
            hint: 'Search product, SKU, or operator…',
            onChanged: changes.add,
          ),
        ),
      );

      expect(find.byIcon(Icons.cancel_rounded), findsNothing);

      await tester.enterText(find.byType(TextField), 'ELEC');
      await tester.pumpAndSettle();
      expect(changes.last, 'ELEC');

      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(changes.last, isEmpty);
    });

    testWidgets('filter pills report selection', (tester) async {
      String? selected;
      await pump(
        tester,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              StockOpsFilterPill(
                label: 'Inbound',
                selected: false,
                count: 12,
                onTap: () => selected = 'Inbound',
              ),
              const SizedBox(width: 8),
              StockOpsFilterPill(
                label: 'Transfer',
                selected: true,
                onTap: () => selected = 'Transfer',
              ),
            ],
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);
      await tester.tap(find.text('Inbound'));
      await tester.pumpAndSettle();
      expect(selected, 'Inbound');
    });
  });
}
