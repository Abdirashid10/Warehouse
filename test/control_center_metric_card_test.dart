import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/warehouse_control_center_body.dart';
import 'package:logisticsmobile/widgets/wms/wms_premium_cards.dart';

/// Overflow + layout contract for the redesigned control-center metric cards.
///
/// The cards live inside fixed-height grid rows, so any change to the type
/// scale, the icon badge or the card padding risks a bottom overflow. These
/// tests pin that contract across the full phone/tablet width range and across
/// accessibility text scales.
void main() {
  /// Widths spanning the smallest supported phone through to a tablet.
  const widths = <double>[320, 360, 375, 393, 412, 430, 480, 600, 768];

  /// Text scales from default up to the platform maximum this app clamps to,
  /// plus one beyond it to prove the scale-down safety net engages.
  const textScales = <double>[1.0, 1.2, 1.3];

  Widget sectionsUnderTest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const ControlCenterOperationsRow(
          activeWarehouses: 4,
          todayMovements: 128,
          totalOrders: 1240,
          delivered: 986,
        ),
        const SizedBox(height: AppSpacing.xxl),
        ControlCenterInventoryOverview(
          // Deliberately large values — the widest strings the card can get.
          unitsOnHand: 1284567,
          inStockLines: 4821,
          lowStock: 37,
          outOfStock: 12,
          stockValue: 98765432.10,
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.xxl),
        ControlCenterOperationalAlerts(
          outOfStock: 12,
          lowStock: 37,
          expired: 4,
          // Exercises the 999+ clamp.
          expiringSoon: 1500,
          pendingOrders: 8,
          // Exercises the zero-state 'Clear' status pill.
          urgentTasks: 0,
          onTap: () {},
        ),
      ],
    );
  }

  Future<List<String>> pumpAndCollectOverflows(
    WidgetTester tester, {
    required double width,
    required double textScale,
    required ThemeData theme,
  }) async {
    final overflows = <String>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed')) {
        overflows.add(message.split('\n').first);
      } else {
        previousHandler?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previousHandler);

    await tester.binding.setSurfaceSize(Size(width, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: sectionsUnderTest(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return overflows;
  }

  group('Control center metric cards', () {
    for (final width in widths) {
      for (final scale in textScales) {
        testWidgets(
          'no overflow at ${width.toInt()}dp @ ${scale}x text',
          (tester) async {
            final overflows = await pumpAndCollectOverflows(
              tester,
              width: width,
              textScale: scale,
              theme: AppTheme.light,
            );
            expect(overflows, isEmpty, reason: overflows.join('\n'));
          },
        );
      }
    }

    testWidgets('no overflow in dark theme at 360dp', (tester) async {
      final overflows = await pumpAndCollectOverflows(
        tester,
        width: 360,
        textScale: 1.2,
        theme: AppTheme.dark,
      );
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });

    testWidgets('single-column layout does not overflow', (tester) async {
      final overflows = <String>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed')) {
          overflows.add(message.split('\n').first);
        } else {
          previousHandler?.call(details);
        }
      };
      addTearDown(() => FlutterError.onError = previousHandler);

      await tester.binding.setSurfaceSize(const Size(320, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: const ControlCenterOperationalAlerts(
                outOfStock: 2,
                lowStock: 9,
                expired: 2,
                expiringSoon: 0,
                pendingOrders: 1,
                urgentTasks: 6,
                forceSingleColumn: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });

    testWidgets('every metric tile in a row shares one height', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: const ControlCenterOperationsRow(
                activeWarehouses: 4,
                todayMovements: 128,
                totalOrders: 1240,
                delivered: 986,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cards = tester.widgetList<WmsMetricCard>(
        find.byType(WmsMetricCard),
      );
      expect(cards, hasLength(4));

      final heights = find
          .byType(WmsMetricCard)
          .evaluate()
          .map((e) => e.size!.height)
          .toSet();
      expect(
        heights,
        hasLength(1),
        reason: 'Tiles must share a single height so rows stay aligned',
      );
      expect(heights.single, WmsPremiumMetricCard.gridExtent);
    });

    testWidgets('alert tiles show Clear when the count is zero',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: const ControlCenterOperationalAlerts(
                outOfStock: 0,
                lowStock: 3,
                expired: 0,
                expiringSoon: 0,
                pendingOrders: 0,
                urgentTasks: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Five zero-count tiles read 'Clear', the one non-zero tile 'Attention'.
      expect(find.text('Clear'), findsNWidgets(5));
      expect(find.text('Attention'), findsOneWidget);
    });
  });
}
