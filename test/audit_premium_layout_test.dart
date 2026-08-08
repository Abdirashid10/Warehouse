import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/audit/domain/repositories/audit_repository.dart';
import 'package:logisticsmobile/features/audit/presentation/cubit/audit_cubit.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_activity_stream.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_premium_theme.dart';

/// Deterministic repository so the stream can be exercised without a backend.
class _FakeAuditRepository implements AuditRepository {
  _FakeAuditRepository(this._activities);

  final List<AuditActivity> _activities;
  static const pages = 1;

  String? lastQuery;
  String? lastModule;
  int calls = 0;

  @override
  Future<AuditPage> getActivities({
    int page = 1,
    int limit = 25,
    String? query,
    String? module,
  }) async {
    calls++;
    lastQuery = query;
    lastModule = module;

    var result = _activities;
    if (module != null) {
      result = result.where((a) => a.module == module).toList();
    }
    if (query != null && query.isNotEmpty) {
      final needle = query.toLowerCase();
      result = result
          .where((a) =>
              a.action.toLowerCase().contains(needle) ||
              a.userName.toLowerCase().contains(needle))
          .toList();
    }

    return AuditPage(
      activities: result,
      page: page,
      pages: pages,
      total: result.length,
    );
  }
}

void main() {
  final now = DateTime.now();
  DateTime hoursAgo(int h) => now.subtract(Duration(hours: h));

  /// Anchors the "Today" fixture to the current instant rather than an offset.
  ///
  /// `now - 2h` falls on *yesterday* whenever the suite runs in the first two
  /// hours after midnight, which made the day-grouping assertions flake by
  /// wall-clock time.
  final today = now;

  List<AuditActivity> sampleActivities() => [
        AuditActivity(
          id: 'act-8f21ab',
          action: 'Stock transferred',
          module: 'Inventory',
          details: 'Moved 240 units from Bakaaro to Madiina Distribution Center',
          userName: 'Ayaan Hassan',
          occurredAt: today,
        ),
        AuditActivity(
          id: 'act-4c90de',
          action: 'Goods received',
          module: 'Inventory',
          details: 'Received 1,200 units against PO-4412',
          userName: 'Mohamed Warsame',
          occurredAt: hoursAgo(30),
        ),
        AuditActivity(
          id: 'act-77bb01',
          action: 'Deleted product',
          module: 'Products',
          details: 'Removed SKU ELEC-HP-001 from the catalogue',
          userName: 'Admin',
          occurredAt: hoursAgo(60),
        ),
        AuditActivity(
          id: 'act-1a2b3c',
          action: 'Task assigned',
          module: 'Tasks',
          details: 'Cycle count assigned to Suuqbacaad team',
          userName: 'Supervisor',
          occurredAt: hoursAgo(200),
        ),
        AuditActivity(
          id: 'act-9z8y7x',
          action: 'User login',
          module: 'Security',
          details: 'Signed in from a new device',
          userName: 'Ayaan Hassan',
          occurredAt: null,
        ),
      ];

  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

  Future<AuditCubit> pumpStream(
    WidgetTester tester, {
    required Size surfaceSize,
    required ThemeData theme,
    List<AuditActivity>? activities,
    _FakeAuditRepository? repository,
    List<FlutterErrorDetails>? errorSink,
  }) async {
    if (errorSink != null) {
      final previousHandler = FlutterError.onError;
      FlutterError.onError = errorSink.add;
      addTearDown(() => FlutterError.onError = previousHandler);
    }

    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = repository ??
        _FakeAuditRepository(activities ?? sampleActivities());
    final cubit = AuditCubit(repo)..load();
    addTearDown(cubit.close);

    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: AuditActivityStream(
              cubit: cubit,
              searchController: searchController,
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    return cubit;
  }

  group('layout', () {
    for (final width in const [320.0, 360.0, 393.0, 412.0]) {
      testWidgets('stream renders clean in light theme at ${width}dp',
          (tester) async {
        final errors = <FlutterErrorDetails>[];
        await pumpStream(
          tester,
          surfaceSize: Size(width, 1400),
          theme: AppTheme.light,
          errorSink: errors,
        );
        expect(
          errors,
          isEmpty,
          reason: errors.map((e) => e.exceptionAsString()).join('\n'),
        );
      });

      testWidgets('stream renders clean in dark theme at ${width}dp',
          (tester) async {
        final errors = <FlutterErrorDetails>[];
        await pumpStream(
          tester,
          surfaceSize: Size(width, 1400),
          theme: AppTheme.dark,
          errorSink: errors,
        );
        expect(
          errors,
          isEmpty,
          reason: errors.map((e) => e.exceptionAsString()).join('\n'),
        );
      });
    }
  });

  group('action taxonomy', () {
    test('destructive wording outranks generic verbs', () {
      // "Deleted product" also contains no update keyword, but "Removed stock
      // record updated" does — a delete must never be filed as an update.
      expect(
        AuditActionClassifier.classify('Removed stock record', 'Inventory').kind,
        AuditActionKind.delete,
      );
      expect(
        AuditActionClassifier.classify('Deleted product', 'Products').kind,
        AuditActionKind.delete,
      );
    });

    test('auth events classify as security, not as an update', () {
      expect(
        AuditActionClassifier.classify('User login', 'Security').kind,
        AuditActionKind.security,
      );
      expect(
        AuditActionClassifier.classify('Role permission changed', 'Users').kind,
        AuditActionKind.security,
      );
    });

    test('movement verbs map onto their own kinds', () {
      expect(
        AuditActionClassifier.classify('Stock transferred', 'Inventory').kind,
        AuditActionKind.transfer,
      );
      expect(
        AuditActionClassifier.classify('Goods received', 'Inventory').kind,
        AuditActionKind.receive,
      );
      expect(
        AuditActionClassifier.classify('Task assigned', 'Tasks').kind,
        AuditActionKind.task,
      );
    });

    test('unrecognised actions fall back to a system event', () {
      final spec = AuditActionClassifier.classify('Ping', 'Platform');
      expect(spec.kind, AuditActionKind.system);
      expect(spec.label, 'Event');
    });
  });

  group('detail parsing', () {
    test('extracts an origin to destination route', () {
      final detail = AuditDetail.parse(
        'Moved 240 units from Bakaaro to Madiina, ref PO-1',
      );
      expect(detail.route, isNotNull);
      expect(detail.route!.origin, 'Bakaaro');
      expect(detail.route!.destination, 'Madiina');
      expect(detail.text, isNot(contains('from Bakaaro to Madiina')));
    });

    test('leaves prose without a route untouched', () {
      const raw = 'Received 1,200 units against PO-4412';
      final detail = AuditDetail.parse(raw);
      expect(detail.route, isNull);
      expect(detail.text, raw);
    });

    test('empty details produce no text and no route', () {
      final detail = AuditDetail.parse('   ');
      expect(detail.text, isEmpty);
      expect(detail.route, isNull);
    });
  });

  group('stamps', () {
    test('reference uses the tail of the id, upper-cased', () {
      expect(AuditStamp.reference('act-8f21ab'), '#8F21AB');
      expect(AuditStamp.reference('x1'), '#X1');
      expect(AuditStamp.reference('---'), '#—');
    });

    test('exact stamp zero-pads day, hour and minute', () {
      expect(AuditStamp.exact(DateTime(2026, 3, 5, 9, 4)), '05 Mar · 09:04');
    });
  });

  group('date window', () {
    test('today keeps only entries from midnight onward', () {
      final activities = [
        AuditActivity(
          id: '1',
          action: 'a',
          module: 'm',
          details: '',
          userName: 'u',
          occurredAt: DateTime.now(),
        ),
        AuditActivity(
          id: '2',
          action: 'b',
          module: 'm',
          details: '',
          userName: 'u',
          occurredAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        const AuditActivity(
          id: '3',
          action: 'c',
          module: 'm',
          details: '',
          userName: 'u',
        ),
      ];

      expect(filterAuditByDate(activities, AuditDateFilter.today).length, 1);
      expect(filterAuditByDate(activities, AuditDateFilter.all).length, 3);
    });
  });

  testWidgets('timeline groups entries by day and shows undated last',
      (tester) async {
    await pumpStream(
      tester,
      surfaceSize: const Size(393, 1400),
      theme: AppTheme.dark,
    );

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('UNDATED'), findsOneWidget);
    expect(find.text('Stock transferred'), findsOneWidget);
    // Route parsed out of the detail line.
    expect(find.text('Bakaaro'), findsOneWidget);
    expect(find.text('Madiina Distribution Center'), findsOneWidget);
    // Monospace reference derived from the entry id.
    expect(find.text('#8F21AB'), findsOneWidget);
  });

  testWidgets('narrowing to Today empties the stream and offers a reset',
      (tester) async {
    final repository = _FakeAuditRepository([
      AuditActivity(
        id: 'old-1',
        action: 'Stock transferred',
        module: 'Inventory',
        details: 'Moved 10 units from A to B',
        userName: 'Ayaan',
        occurredAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
    ]);

    await pumpStream(
      tester,
      surfaceSize: const Size(393, 1000),
      theme: AppTheme.light,
      repository: repository,
    );

    expect(find.text('Stock transferred'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await settle(tester);

    expect(find.text('No audit entries'), findsOneWidget);
    expect(find.text('Reset filters'), findsOneWidget);

    await tester.tap(find.text('Reset filters'));
    await settle(tester);

    expect(find.text('Stock transferred'), findsOneWidget);
    expect(find.text('No audit entries'), findsNothing);
  });

  testWidgets('category chips carry counts and drive the module filter',
      (tester) async {
    final repository = _FakeAuditRepository(sampleActivities());

    await pumpStream(
      tester,
      surfaceSize: const Size(393, 1400),
      theme: AppTheme.dark,
      repository: repository,
    );

    // "All" appears twice by design: the date window and the category bucket.
    expect(find.text('All'), findsNWidgets(2));
    expect(find.text('Inventory'), findsWidgets);
    // Two Inventory entries in the fixture.
    expect(find.text('2'), findsWidgets);

    await tester.tap(find.text('Inventory').first);
    await settle(tester);

    expect(repository.lastModule, 'Inventory');
    expect(find.text('Deleted product'), findsNothing);
  });

  testWidgets('search box clears and re-queries', (tester) async {
    final repository = _FakeAuditRepository(sampleActivities());

    await pumpStream(
      tester,
      surfaceSize: const Size(393, 1400),
      theme: AppTheme.light,
      repository: repository,
    );

    await tester.enterText(find.byType(TextField), 'Warsame');
    await settle(tester);

    expect(repository.lastQuery, 'Warsame');
    expect(find.text('Goods received'), findsOneWidget);
    expect(find.text('Stock transferred'), findsNothing);

    await tester.tap(find.byIcon(Icons.cancel_rounded));
    await settle(tester);

    expect(repository.lastQuery, isNull);
    expect(find.text('Stock transferred'), findsOneWidget);
  });
}
