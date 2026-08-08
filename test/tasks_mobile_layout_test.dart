import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/core/utils/task_workflow_utils.dart';
import 'package:logisticsmobile/features/tasks/domain/entities/warehouse_task.dart';
import 'package:logisticsmobile/features/tasks/presentation/cubit/tasks_cubit.dart';
import 'package:logisticsmobile/features/tasks/presentation/widgets/tasks_enterprise_widgets.dart';
import 'package:logisticsmobile/widgets/wms/wms_metric_pill.dart';

/// Layout contract for the redesigned Tasks screen.
void main() {
  // Widget tests must never reach the network: each pumpWidget would
  // otherwise stall on a Google Fonts fetch.
  GoogleFonts.config.allowRuntimeFetching = false;

  const widths = <double>[320, 360, 375, 393, 412, 430, 480];
  const textScales = <double>[1.0, 1.2, 1.3];

  WarehouseTask task({
    String title = 'Pick order #1042 for outbound dispatch',
    String status = WmsTaskStatuses.accepted,
    String priority = 'High',
  }) =>
      WarehouseTask(
        id: title,
        title: title,
        status: status,
        priority: priority,
        taskType: 'Picking & Consolidation',
        productName: 'Blue Ballpoint Pen (Box of 50 units)',
        warehouseName: 'Central Distribution Center — North Bay',
        assignedToName: 'Ali Hassan Mohamed',
        dueDate: DateTime(2026, 8, 6),
        createdAt: DateTime(2026, 8, 4),
      );

  const summary = TasksSummary(
    total: 128,
    awaiting: 12,
    accepted: 8,
    inProgress: 5,
    completed: 96,
    rejected: 3,
    overdue: 4,
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

  Widget card({
    String status = WmsTaskStatuses.accepted,
    bool isManager = true,
    void Function(TaskWorkflowAction)? onAction,
  }) =>
      TaskEnterpriseCard(
        task: task(status: status),
        isManager: isManager,
        onView: () {},
        onEdit: () {},
        onReassign: () {},
        onAction: onAction ?? (_) {},
      );

  group('TaskEnterpriseCard', () {
    for (final width in widths) {
      for (final scale in textScales) {
        testWidgets('no overflow at ${width.toInt()}dp @ ${scale}x',
            (tester) async {
          final overflows = await pump(
            tester,
            width: width,
            textScale: scale,
            child: Column(
              children: [
                card(),
                const SizedBox(height: 8),
                card(status: WmsTaskStatuses.completed),
              ],
            ),
          );
          expect(overflows, isEmpty, reason: overflows.join('\n'));
        });
      }
    }

    testWidgets('is shorter than the chip-wrapping layout it replaced',
        (tester) async {
      await pump(tester, width: 393, textScale: 1.0, child: card());
      final height = tester.getSize(find.byType(TaskEnterpriseCard)).height;
      // Five action chips wrapping across two or three runs pushed the old
      // card past 330dp.
      expect(height, lessThan(250));
    });

    testWidgets('title and meta lines stay single-line', (tester) async {
      await pump(tester, width: 320, textScale: 1.0, child: card());

      for (final text in [
        'Pick order #1042 for outbound dispatch',
        'Blue Ballpoint Pen (Box of 50 units)',
        'Central Distribution Center — North Bay',
        'Ali Hassan Mohamed',
      ]) {
        final widget = tester.widget<Text>(find.text(text));
        expect(widget.maxLines, 1, reason: '$text should be single-line');
        expect(widget.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('exposes one primary action, the rest behind the menu',
        (tester) async {
      await pump(tester, width: 393, textScale: 1.0, child: card());

      final actions = TaskWorkflowUtils.getCardActions(
        task(),
        isManager: true,
      );
      expect(actions, isNotEmpty, reason: 'fixture must have card actions');

      // Primary is a real button on the card.
      expect(find.widgetWithText(FilledButton, actions.first.label),
          findsOneWidget);
      // Manager actions are not on the card surface until the menu opens.
      expect(find.text('Reassign'), findsNothing);
      expect(find.text('Edit task'), findsNothing);

      await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
      await tester.pumpAndSettle();

      expect(find.text('View details'), findsOneWidget);
      expect(find.text('Reassign'), findsOneWidget);
      expect(find.text('Edit task'), findsOneWidget);
    });

    testWidgets('non-managers do not get reassign or edit', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: card(isManager: false),
      );

      await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
      await tester.pumpAndSettle();

      expect(find.text('View details'), findsOneWidget);
      expect(find.text('Reassign'), findsNothing);
      expect(find.text('Edit task'), findsNothing);
    });

    testWidgets('primary button fires the first workflow action',
        (tester) async {
      TaskWorkflowAction? fired;
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: card(onAction: (a) => fired = a),
      );

      final expected =
          TaskWorkflowUtils.getCardActions(task(), isManager: true).first;
      await tester.tap(find.widgetWithText(FilledButton, expected.label));
      await tester.pumpAndSettle();

      expect(fired?.targetStatus, expected.targetStatus);
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

  group('TasksKpiStrip', () {
    Widget strip({String? selected}) => TasksKpiStrip(
          summary: summary,
          selectedFilter: selected,
          onFilterTap: (_) {},
        );

    testWidgets('seven metrics occupy one strip row', (tester) async {
      await pump(tester, width: 393, textScale: 1.0, child: strip());

      expect(
        tester.getSize(find.byType(TasksKpiStrip)).height,
        WmsMetricPillBar.height,
      );
      expect(
        tester.widget<WmsMetricPillBar>(find.byType(WmsMetricPillBar)).metrics,
        hasLength(7),
      );
    });

    testWidgets('the active pill reflects the status filter', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: strip(selected: TaskKpiFilter.inProgress),
      );

      final metrics =
          tester.widget<WmsMetricPillBar>(find.byType(WmsMetricPillBar)).metrics;
      expect(metrics.where((m) => m.selected), hasLength(1));
      expect(metrics.firstWhere((m) => m.selected).label, 'In Progress');
    });

    testWidgets('tapping the active pill clears the filter', (tester) async {
      Object? emitted = 'unset';
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: TasksKpiStrip(
          summary: summary,
          selectedFilter: TaskKpiFilter.awaiting,
          onFilterTap: (v) => emitted = v,
        ),
      );

      await tester.tap(find.text('Awaiting'));
      await tester.pumpAndSettle();
      expect(emitted, isNull);
    });

    for (final width in [320.0, 360.0, 430.0]) {
      testWidgets('no overflow at ${width.toInt()}dp', (tester) async {
        final overflows = await pump(
          tester,
          width: width,
          textScale: 1.3,
          child: strip(),
        );
        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }
  });
}
