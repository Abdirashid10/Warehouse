import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/admin/presentation/cubit/administration_cubit.dart';
import 'package:logisticsmobile/features/admin/presentation/pages/administration_screen.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_activity_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_alerts_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_atoms.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_theme.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_roles_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_users_panel.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_warehouses_panel.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:logisticsmobile/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:logisticsmobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:logisticsmobile/features/users/domain/entities/create_user_input.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/users/domain/repositories/users_repository.dart';
import 'package:logisticsmobile/features/users/presentation/cubit/users_cubit.dart';
import 'package:logisticsmobile/features/warehouses/domain/entities/warehouse.dart';
import 'package:logisticsmobile/widgets/wms/wms_pill_tab_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fakes
// ─────────────────────────────────────────────────────────────────────────────

class _FakeUsersRepository implements UsersRepository {
  _FakeUsersRepository(this.users);

  final List<WmsUser> users;

  @override
  Future<List<WmsUser>> getUsers() async => users;

  @override
  Future<WmsUser> createUser(CreateUserInput input) =>
      throw UnimplementedError();

  @override
  Future<WmsUser> updateUserStatus({
    required String id,
    required String status,
  }) =>
      throw UnimplementedError();
}

class _FakeNotificationsRepository implements NotificationsRepository {
  _FakeNotificationsRepository(this.items);

  final List<AppNotification> items;

  @override
  Future<({List<AppNotification> items, int unreadCount})>
      getNotifications() async =>
          (items: items, unreadCount: items.where((n) => !n.read).length);
}

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures
// ─────────────────────────────────────────────────────────────────────────────

final _now = DateTime.now();

List<WmsUser> _sampleUsers() => [
      WmsUser(
        id: 'u1',
        username: 'ayaan',
        email: 'ayaan@logistics.example',
        role: 'Admin',
        status: 'Active',
        fullName: 'Ayaan Hassan',
        assignedWarehouse: 'Bakaaro',
        lastLoginAt: _now.subtract(const Duration(hours: 3)),
      ),
      WmsUser(
        id: 'u2',
        username: 'mohamed',
        email: 'mohamed@logistics.example',
        role: 'Supervisor',
        status: 'Active',
        fullName: 'Mohamed Abdullahi Warsame',
        assignedWarehouse: 'Madiina Distribution Center',
        lastLoginAt: _now.subtract(const Duration(days: 2)),
      ),
      const WmsUser(
        id: 'u3',
        username: 'khadija',
        email: 'khadija@logistics.example',
        role: 'Staff',
        status: 'Inactive',
        fullName: 'Khadija Omar',
      ),
    ];

const _sampleWarehouses = [
  Warehouse(
    id: 'w1',
    name: 'Bakaaro',
    location: 'Mogadishu — Bakaaro Market District',
    capacity: 12000,
    staffCount: 14,
    totalUnits: 11400,
    utilization: 95,
  ),
  Warehouse(
    id: 'w2',
    name: 'Madiina Distribution Center',
    location: 'Madiina',
    capacity: 8000,
    staffCount: 7,
    totalUnits: 3200,
    utilization: 40,
  ),
];

List<AuditActivity> _sampleActivities() => [
      AuditActivity(
        id: 'act-8f21ab',
        action: 'Stock transferred',
        module: 'Inventory',
        details: 'Moved 240 units from Bakaaro to Madiina Distribution Center',
        userName: 'Ayaan Hassan',
        // Anchored to the current instant: `now - 2h` lands on yesterday when
        // the suite runs just after midnight, which flaked the day grouping.
        occurredAt: _now,
      ),
      AuditActivity(
        id: 'act-77bb01',
        action: 'Deleted product',
        module: 'Products',
        details: 'Removed SKU ELEC-HP-001 from the catalogue',
        userName: 'Admin',
        occurredAt: _now.subtract(const Duration(days: 2)),
      ),
    ];

List<AppNotification> _sampleAlerts() => [
      AppNotification(
        id: 'n1',
        title: 'Bakaaro is out of stock on ELEC-HP-001',
        message: 'Zero units remain against an open order.',
        type: 'out_of_stock',
        read: false,
        createdAt: _now.subtract(const Duration(minutes: 30)),
      ),
      AppNotification(
        id: 'n2',
        title: 'Low stock threshold breached',
        message: 'Madiina fell below the reorder point for 3 SKUs.',
        type: 'low_stock',
        read: false,
        createdAt: _now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'n3',
        title: 'Cycle count completed',
        message: 'Suuqbacaad finished its scheduled count.',
        type: 'task_completed',
        read: true,
        createdAt: _now.subtract(const Duration(days: 1)),
      ),
    ];

AdministrationBundle _sampleBundle() {
  final alerts = _sampleAlerts();
  return AdministrationBundle(
    users: _sampleUsers(),
    warehouses: _sampleWarehouses,
    auditActivities: _sampleActivities(),
    auditTotal: 2,
    notifications: alerts,
    unreadCount: alerts.where((n) => !n.read).length,
  );
}

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

  Future<void> pumpConsoleSurfaces(
    WidgetTester tester, {
    required Size surfaceSize,
    required ThemeData theme,
  }) async {
    final errors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousHandler);

    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final bundle = _sampleBundle();

    final usersCubit = UsersCubit(_FakeUsersRepository(_sampleUsers()))..load();
    addTearDown(usersCubit.close);

    final notificationsCubit = NotificationsCubit(
      GetNotificationsUseCase(_FakeNotificationsRepository(_sampleAlerts())),
    )..load();
    addTearDown(notificationsCubit.close);

    final searchController = TextEditingController();
    addTearDown(searchController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ListView(
            children: [
              AdminHeroBanner(
                title: 'Administration Center',
                subtitle: 'Identity, access, infrastructure and compliance',
                trailing: const AdminStatusChip(
                  label: 'Console',
                  color: Colors.white,
                  icon: Icons.lock_rounded,
                ),
                child: AdminBentoGrid(bundle: bundle),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 1500,
                  child: BlocProvider.value(
                    value: usersCubit,
                    child: AdminUsersPanel(
                      cubit: usersCubit,
                      searchController: searchController,
                      padding: false,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 2200,
                  child: AdminRolesPanel(bundle: bundle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 1400,
                  child: AdminWarehousesPanel(bundle: bundle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 1000,
                  child: AdminActivityPanel(
                    activities: bundle.auditActivities,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 1200,
                  child: AdminAlertsPanel(cubit: notificationsCubit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);

    expect(
      errors,
      isEmpty,
      reason: errors.map((e) => e.exceptionAsString()).join('\n'),
    );
  }

  group('layout', () {
    for (final width in const [320.0, 360.0, 393.0, 412.0]) {
      testWidgets('console surfaces render clean in light theme at ${width}dp',
          (tester) async {
        await pumpConsoleSurfaces(
          tester,
          surfaceSize: Size(width, 2200),
          theme: AppTheme.light,
        );
      });

      testWidgets('console surfaces render clean in dark theme at ${width}dp',
          (tester) async {
        await pumpConsoleSurfaces(
          tester,
          surfaceSize: Size(width, 2200),
          theme: AppTheme.dark,
        );
      });
    }
  });

  group('role tiers', () {
    test('directory role strings map onto access tiers', () {
      expect(AdminRoles.tierOf('Admin'), AdminRoleTier.admin);
      expect(AdminRoles.tierOf('system administrator'), AdminRoleTier.admin);
      expect(AdminRoles.tierOf('Supervisor'), AdminRoleTier.supervisor);
      expect(AdminRoles.tierOf('Warehouse Manager'), AdminRoleTier.supervisor);
      expect(AdminRoles.tierOf('Staff'), AdminRoleTier.staff);
      expect(AdminRoles.tierOf('picker'), AdminRoleTier.staff);
      expect(AdminRoles.tierOf('contractor'), AdminRoleTier.unknown);
    });

    testWidgets('each tier gets a distinct identity colour', (tester) async {
      late AdminPalette palette;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              palette = AdminPalette.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final colours = {
        for (final tier in AdminRoleTier.values) palette.roleColor(tier),
      };
      expect(colours.length, AdminRoleTier.values.length);
    });
  });

  group('capability matrix', () {
    test('admin holds every capability', () {
      final held = AdminRolesCatalog.capabilities
          .where((c) => c.grantedTo(AdminRoleTier.admin))
          .length;
      expect(held, AdminRolesCatalog.capabilities.length);
    });

    test('staff never holds identity or compliance capabilities', () {
      final staffCapabilities = AdminRolesCatalog.capabilities
          .where((c) => c.grantedTo(AdminRoleTier.staff))
          .map((c) => c.label)
          .toList();

      expect(staffCapabilities, isNot(contains('User & role management')));
      expect(staffCapabilities, isNot(contains('Audit & compliance logs')));
      expect(staffCapabilities, isNot(contains('System configuration')));
    });

    test('supervisor sits strictly between staff and admin', () {
      int countFor(AdminRoleTier tier) => AdminRolesCatalog.capabilities
          .where((c) => c.grantedTo(tier))
          .length;

      expect(countFor(AdminRoleTier.staff),
          lessThan(countFor(AdminRoleTier.supervisor)));
      expect(countFor(AdminRoleTier.supervisor),
          lessThan(countFor(AdminRoleTier.admin)));
    });
  });

  group('alert severity', () {
    AppNotification alert(String type, {String title = 'Alert'}) =>
        AppNotification(
          id: type,
          title: title,
          message: '',
          type: type,
          read: false,
        );

    test('failure wording outranks softer keywords', () {
      // "out_of_stock" also reads as a stock event; it must not soften to a
      // warning just because "stock" appears.
      expect(alertSeverityOf(alert('out_of_stock')), AlertSeverity.critical);
      expect(alertSeverityOf(alert('task_overdue')), AlertSeverity.critical);
    });

    test('threshold events are warnings', () {
      expect(alertSeverityOf(alert('low_stock')), AlertSeverity.warning);
      expect(alertSeverityOf(alert('expiring_soon')), AlertSeverity.warning);
    });

    test('completion events resolve', () {
      expect(alertSeverityOf(alert('task_completed')), AlertSeverity.success);
      expect(alertSeverityOf(alert('order_delivered')), AlertSeverity.success);
    });

    test('anything unrecognised is informational', () {
      expect(alertSeverityOf(alert('newsletter')), AlertSeverity.info);
    });
  });

  testWidgets('bento grid reports live counts and a real active ratio',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdminBentoGrid(bundle: _sampleBundle()),
          ),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // three non-archived accounts
    expect(find.text('Active Sessions'), findsOneWidget);
    // Two of three accounts are active — the caption states the real ratio.
    expect(find.text('67% of directory'), findsOneWidget);
    expect(find.text('Warehouses'), findsOneWidget);
    expect(find.text('Unread Alerts'), findsOneWidget);
    expect(find.text('of 3 total alerts'), findsOneWidget);
  });

  testWidgets('user cards expose role, status and structured metadata',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdminUserCard(user: _sampleUsers().first),
          ),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Ayaan Hassan'), findsOneWidget);
    expect(find.text('@ayaan'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('ayaan@logistics.example'), findsOneWidget);
    expect(find.text('Bakaaro'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Last login'), findsOneWidget);
  });

  testWidgets('a user who never signed in says so rather than showing a date',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdminUserCard(user: _sampleUsers().last),
          ),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Never signed in'), findsOneWidget);
    expect(find.text('Not assigned'), findsOneWidget);
  });

  testWidgets('alerts filter by severity and reset from the empty state',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = NotificationsCubit(
      GetNotificationsUseCase(_FakeNotificationsRepository(_sampleAlerts())),
    )..load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: AdminAlertsPanel(cubit: cubit)),
      ),
    );
    await settle(tester);

    expect(find.text('Bakaaro is out of stock on ELEC-HP-001'), findsOneWidget);
    expect(find.text('Cycle count completed'), findsOneWidget);

    // Narrow to critical only. The filter bar scrolls horizontally, so each
    // pill has to be brought into view before it can be tapped.
    await tester.ensureVisible(find.text('Critical').first);
    await settle(tester);
    await tester.tap(find.text('Critical').first);
    await settle(tester);

    expect(find.text('Bakaaro is out of stock on ELEC-HP-001'), findsOneWidget);
    expect(find.text('Cycle count completed'), findsNothing);

    // Switching severity replaces the filter rather than stacking it.
    await tester.ensureVisible(find.text('Resolved').first);
    await settle(tester);
    await tester.tap(find.text('Resolved').first);
    await settle(tester);

    expect(find.text('Bakaaro is out of stock on ELEC-HP-001'), findsNothing);
    expect(find.text('Cycle count completed'), findsOneWidget);
  });

  testWidgets('alerts empty state offers a reset that restores the feed',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Only a resolved alert exists, so filtering to unread empties the list.
    final cubit = NotificationsCubit(
      GetNotificationsUseCase(
        _FakeNotificationsRepository([_sampleAlerts().last]),
      ),
    )..load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: AdminAlertsPanel(cubit: cubit)),
      ),
    );
    await settle(tester);

    expect(find.text('Cycle count completed'), findsOneWidget);

    await tester.tap(find.text('Unread').first);
    await settle(tester);

    expect(find.text('No matching alerts'), findsOneWidget);
    expect(find.text('Reset filters'), findsOneWidget);

    await tester.tap(find.text('Reset filters'));
    await settle(tester);

    expect(find.text('Cycle count completed'), findsOneWidget);
    expect(find.text('No matching alerts'), findsNothing);
  });

  testWidgets('activity tab renders the audit timeline with parsed routes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AdminActivityPanel(activities: _sampleActivities()),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('System Activity'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('Stock transferred'), findsOneWidget);
    // The route is parsed out of the detail line by the audit components.
    expect(find.text('Bakaaro'), findsOneWidget);
    expect(find.text('Madiina Distribution Center'), findsOneWidget);
  });

  testWidgets('console navigation slides between all seven surfaces',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final errors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousHandler);

    const tabs = [
      WmsPillTabSpec(label: 'Users', icon: Icons.groups_rounded),
      WmsPillTabSpec(label: 'Roles', icon: Icons.admin_panel_settings_rounded),
      WmsPillTabSpec(label: 'Warehouses', icon: Icons.warehouse_rounded),
      WmsPillTabSpec(label: 'Audit', icon: Icons.shield_rounded),
      WmsPillTabSpec(label: 'Activity', icon: Icons.timeline_rounded),
      WmsPillTabSpec(label: 'Alerts', icon: Icons.notifications_active_rounded),
      WmsPillTabSpec(label: 'Account', icon: Icons.badge_rounded),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = DefaultTabController.of(context);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: AdminPillTabBar(
                        controller: controller,
                        tabs: tabs,
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: controller,
                        children: [
                          for (final tab in tabs)
                            Center(child: Text('${tab.label} surface')),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Users surface'), findsOneWidget);

    await tester.tap(find.text('Roles'));
    await settle(tester);
    expect(find.text('Roles surface'), findsOneWidget);

    // 'Alerts' sits past the fold on a 320dp device — the bar must scroll it
    // into view before it is tappable.
    await tester.ensureVisible(find.text('Alerts'));
    await settle(tester);
    await tester.tap(find.text('Alerts'));
    await settle(tester);
    expect(find.text('Alerts surface'), findsOneWidget);

    expect(
      errors,
      isEmpty,
      reason: errors.map((e) => e.exceptionAsString()).join('\n'),
    );
  });
}
