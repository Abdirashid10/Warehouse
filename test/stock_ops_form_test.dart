import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/widgets/stock_ops_form_widgets.dart';

/// Layout and behaviour contract for the redesigned Stock Operations form.
void main() {
  const widths = <double>[320, 360, 375, 393, 412, 430, 480];
  const textScales = <double>[1.0, 1.2, 1.3];

  Future<List<String>> pump(
    WidgetTester tester, {
    required double width,
    required double textScale,
    required Widget child,
    ThemeData? theme,
    int? tabCount,
    bool settle = true,
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

    Widget body = Scaffold(body: child);
    if (tabCount != null) {
      body = DefaultTabController(length: tabCount, child: body);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: body,
          ),
        ),
      ),
    );
    // An indeterminate progress indicator never settles.
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return overflows;
  }

  Widget section({bool collapsible = false, bool expanded = true}) {
    return StockOpsFormSection(
      title: 'Product & Quantity',
      subtitle: 'What is moving, and how much',
      icon: Icons.inventory_2_outlined,
      collapsible: collapsible,
      initiallyExpanded: expanded,
      filledCount: 2,
      children: [
        StockOpsTextField(
          controller: TextEditingController(),
          label: 'Quantity',
          required: true,
        ),
      ],
    );
  }

  group('StockOpsFormSection', () {
    for (final width in widths) {
      for (final scale in textScales) {
        testWidgets('no overflow at ${width.toInt()}dp @ ${scale}x',
            (tester) async {
          final overflows = await pump(
            tester,
            width: width,
            textScale: scale,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(children: [section(), section(collapsible: true)]),
            ),
          );
          expect(overflows, isEmpty, reason: overflows.join('\n'));
        });
      }
    }

    testWidgets('collapsible section hides and reveals its fields',
        (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: section(collapsible: true, expanded: false),
        ),
      );

      // Collapsed: the "n set" hint stands in for the hidden fields.
      expect(find.text('2 set'), findsOneWidget);

      await tester.tap(find.text('Product & Quantity'));
      await tester.pumpAndSettle();

      expect(find.text('2 set'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('required fields are marked with an asterisk', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: section(),
        ),
      );
      expect(find.text('Quantity *'), findsOneWidget);
    });
  });

  group('StockOpsSummaryCard', () {
    testWidgets('renders every metric and an optional warning', (tester) async {
      final overflows = await pump(
        tester,
        width: 320,
        textScale: 1.3,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: StockOpsSummaryCard(
            warning: 'Cannot dispatch more than the available quantity.',
            metrics: [
              StockOpsSummaryMetric(
                label: 'Available Stock',
                value: '1,284,567',
                emphasis: true,
              ),
              StockOpsSummaryMetric(label: 'Reorder Level', value: '50'),
              StockOpsSummaryMetric(
                label: 'Warehouse',
                value: 'Central Distribution Center',
              ),
            ],
          ),
        ),
      );

      expect(overflows, isEmpty, reason: overflows.join('\n'));
      expect(find.text('SUMMARY'), findsOneWidget);
      expect(find.text('1,284,567'), findsOneWidget);
      expect(
        find.text('Cannot dispatch more than the available quantity.'),
        findsOneWidget,
      );
    });
  });

  group('StockOpsSubmitBar', () {
    testWidgets('is disabled and shows the blocking hint', (tester) async {
      var tapped = false;
      await pump(
        tester,
        width: 360,
        textScale: 1.0,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: StockOpsSubmitBar(
            label: 'Submit Operation',
            icon: Icons.send_rounded,
            enabled: false,
            hint: 'Enter a quantity greater than zero',
            onSubmit: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Enter a quantity greater than zero'), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(tapped, isFalse, reason: 'A blocked form must not submit');
    });

    testWidgets('submits when enabled', (tester) async {
      var tapped = false;
      await pump(
        tester,
        width: 360,
        textScale: 1.0,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: StockOpsSubmitBar(
            label: 'Submit Operation',
            icon: Icons.send_rounded,
            onSubmit: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('label is pure white against the filled background',
        (tester) async {
      await pump(
        tester,
        width: 360,
        textScale: 1.0,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: StockOpsSubmitBar(
            label: 'Submit Operation',
            icon: Icons.send_rounded,
            onSubmit: () {},
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Submit Operation')).style?.color,
        const Color(0xFFFFFFFF),
      );
    });

    testWidgets('shows a spinner instead of the label while submitting',
        (tester) async {
      await pump(
        tester,
        width: 360,
        textScale: 1.0,
        settle: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: StockOpsSubmitBar(
            label: 'Submit Operation',
            icon: Icons.send_rounded,
            submitting: true,
            onSubmit: () {},
          ),
        ),
      );
      expect(find.text('Submitting…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('StockOpsTabBar', () {
    const tabs = [
      StockOpsTab(label: 'Receive', icon: Icons.download_rounded),
      StockOpsTab(label: 'Dispatch', icon: Icons.upload_rounded),
      StockOpsTab(label: 'Transfer', icon: Icons.swap_horiz_rounded),
      StockOpsTab(label: 'Return', icon: Icons.assignment_return_outlined),
      StockOpsTab(label: 'History', icon: Icons.history_rounded, badge: 128),
      StockOpsTab(label: 'Alerts', icon: Icons.warning_amber_rounded, badge: 7),
    ];

    for (final width in [320.0, 360.0, 393.0]) {
      testWidgets('scrolls without overflow at ${width.toInt()}dp',
          (tester) async {
        final overflows = await pump(
          tester,
          width: width,
          textScale: 1.0,
          tabCount: 6,
          child: const Align(
            alignment: Alignment.topCenter,
            child: StockOpsTabBar(tabs: tabs),
          ),
        );
        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }

    testWidgets('renders count badges and clamps large ones', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        tabCount: 2,
        child: const Align(
          alignment: Alignment.topCenter,
          child: StockOpsTabBar(
            tabs: [
              StockOpsTab(label: 'History', icon: Icons.history_rounded, badge: 1280),
              StockOpsTab(label: 'Alerts', icon: Icons.warning_amber_rounded, badge: 7),
            ],
          ),
        ),
      );
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('zero counts render no badge', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        tabCount: 1,
        child: const Align(
          alignment: Alignment.topCenter,
          child: StockOpsTabBar(
            tabs: [
              StockOpsTab(label: 'Alerts', icon: Icons.warning_amber_rounded, badge: 0),
            ],
          ),
        ),
      );
      expect(find.text('0'), findsNothing);
    });

    testWidgets('stays within the pinned header extent', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        tabCount: 6,
        child: const Align(
          alignment: Alignment.topCenter,
          child: StockOpsTabBar(tabs: tabs),
        ),
      );
      final height = tester.getSize(find.byType(StockOpsTabBar)).height;
      expect(height, StockOpsTabBar.height);
    });
  });
}
