import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/orders/domain/entities/warehouse_order.dart';
import 'package:logisticsmobile/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:logisticsmobile/features/orders/presentation/widgets/orders_enterprise_widgets.dart';
import 'package:logisticsmobile/widgets/wms/wms_metric_pill.dart';

/// Layout contract for the redesigned Orders screen.
void main() {
  const widths = <double>[320, 360, 375, 393, 412, 430, 480];
  const textScales = <double>[1.0, 1.2, 1.3];

  WarehouseOrder order({
    String no = 'ORD-2026-008',
    String status = WmsOrderStatuses.delivered,
    num total = 30000,
    String customer = 'Acme Corporation International Holdings',
  }) =>
      WarehouseOrder(
        id: no,
        orderNumber: no,
        status: status,
        customerName: customer,
        itemCount: 3,
        grandTotal: total,
        createdAt: DateTime(2026, 8, 5),
        items: const [],
      );

  OrdersViewState viewState({String? statusFilter}) => OrdersViewState(
        orders: [
          order(),
          order(no: 'ORD-2026-007', status: WmsOrderStatuses.pending),
          order(no: 'ORD-2026-006', status: WmsOrderStatuses.processing),
        ],
        stats:
            const OrderStats(actionable: 4, processing: 2, packed: 1, shipped: 3),
        inventory: const [],
        products: const [],
        notifications: const [],
        statusFilter: statusFilter,
      );

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

    await tester.binding.setSurfaceSize(Size(width, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return overflows;
  }

  Widget card({String status = WmsOrderStatuses.delivered}) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: OrdersMobileCard(
          order: order(status: status),
          warehouse: 'Central Distribution Center — Bay 14',
          onTap: () {},
        ),
      );

  group('OrdersMobileCard', () {
    for (final width in widths) {
      for (final scale in textScales) {
        testWidgets('no overflow at ${width.toInt()}dp @ ${scale}x',
            (tester) async {
          final overflows = await pump(
            tester,
            width: width,
            textScale: scale,
            child: card(),
          );
          expect(overflows, isEmpty, reason: overflows.join('\n'));
        });
      }
    }

    testWidgets('is far shorter than the stacked layout it replaced',
        (tester) async {
      await pump(tester, width: 393, textScale: 1.0, child: card());
      final height = tester.getSize(find.byType(OrdersMobileCard)).height;
      // Seven stacked rows plus a 44dp button previously ran past 300dp.
      expect(height, lessThan(210));
    });

    testWidgets('shows id, badge, customer, location, total and date',
        (tester) async {
      await pump(tester, width: 393, textScale: 1.0, child: card());

      expect(find.text('ORD-2026-008'), findsOneWidget);
      expect(find.text('Acme Corporation International Holdings'),
          findsOneWidget);
      expect(find.text('Central Distribution Center — Bay 14'), findsOneWidget);
      expect(find.text('Aug 5'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
      // Amount is rendered; exact formatting comes from WmsFormatters.
      expect(find.textContaining('30,000'), findsOneWidget);
    });

    testWidgets('identity and party lines stay single-line', (tester) async {
      await pump(tester, width: 320, textScale: 1.0, child: card());

      for (final text in [
        'ORD-2026-008',
        'Acme Corporation International Holdings',
        'Central Distribution Center — Bay 14',
      ]) {
        final widget = tester.widget<Text>(find.text(text));
        expect(widget.maxLines, 1, reason: '$text should be single-line');
        expect(widget.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('the amount stays neutral rather than tinted by status',
        (tester) async {
      // Tinting money by order status reads as a payment state.
      final colors = <Color?>{};
      for (final status in [
        WmsOrderStatuses.delivered,
        WmsOrderStatuses.pending,
        WmsOrderStatuses.processing,
      ]) {
        await pump(tester, width: 393, textScale: 1.0, child: card(status: status));
        colors.add(
          tester.widget<Text>(find.textContaining('30,000')).style?.color,
        );
      }
      expect(colors, hasLength(1), reason: 'Amount color must not vary by status');
    });

    testWidgets('renders in dark theme without overflow', (tester) async {
      final overflows = await pump(
        tester,
        width: 360,
        textScale: 1.2,
        theme: AppTheme.dark,
        child: card(),
      );
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });
  });

  group('OrdersMobileKpiGrid', () {
    testWidgets('five stages occupy one strip row', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: OrdersMobileKpiGrid(data: viewState(), onStatusTap: (_) {}),
      );

      expect(
        tester.getSize(find.byType(OrdersMobileKpiGrid)).height,
        WmsMetricPillBar.height,
      );
      expect(
        tester.widget<WmsMetricPillBar>(find.byType(WmsMetricPillBar)).metrics,
        hasLength(5),
      );
    });

    testWidgets('the active stage pill reflects the status filter',
        (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: OrdersMobileKpiGrid(
          data: viewState(statusFilter: WmsOrderStatuses.pending),
          onStatusTap: (_) {},
        ),
      );

      final metrics =
          tester.widget<WmsMetricPillBar>(find.byType(WmsMetricPillBar)).metrics;
      expect(metrics.where((m) => m.selected), hasLength(1));
      expect(metrics.firstWhere((m) => m.selected).label, 'Pending');
    });

    testWidgets('tapping the active stage clears the filter', (tester) async {
      Object? emitted = 'unset';
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: OrdersMobileKpiGrid(
          data: viewState(statusFilter: WmsOrderStatuses.pending),
          onStatusTap: (v) => emitted = v,
        ),
      );

      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();
      expect(emitted, isNull);
    });

    for (final width in [320.0, 360.0, 430.0]) {
      testWidgets('no overflow at ${width.toInt()}dp', (tester) async {
        final overflows = await pump(
          tester,
          width: width,
          textScale: 1.3,
          child: OrdersMobileKpiGrid(data: viewState(), onStatusTap: (_) {}),
        );
        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }
  });

  group('OrdersMobileSearchSection', () {
    Widget searchSection({String? statusFilter}) => OrdersMobileSearchSection(
          data: viewState(statusFilter: statusFilter),
          searchController: TextEditingController(),
          onSearch: (_) {},
          onStatusFilter: (_) {},
        );

    for (final width in [320.0, 360.0, 393.0]) {
      testWidgets('search + chips fit one line each at ${width.toInt()}dp',
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

    testWidgets('whole header stays compact', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: searchSection(),
      );
      final height =
          tester.getSize(find.byType(OrdersMobileSearchSection)).height;
      // One 44dp field + one 34dp chip strip + gap.
      expect(height, lessThan(100));
    });

    testWidgets('chip strip scrolls rather than wrapping', (tester) async {
      await pump(
        tester,
        width: 320,
        textScale: 1.0,
        child: searchSection(),
      );
      final strip = find.byType(ListView);
      expect(strip, findsOneWidget);
      expect(tester.getSize(strip).height, lessThanOrEqualTo(34.0));
    });
  });
}
