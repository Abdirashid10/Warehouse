import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:logisticsmobile/features/auth/domain/usecases/validate_session_usecase.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/products/presentation/widgets/products_enterprise_widgets.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_drawer_widgets.dart';
import 'package:logisticsmobile/features/shell/presentation/widgets/wms_app_drawer.dart';

import 'fakes/fake_auth_repository.dart';

/// Geometry contract for the two system-inset regressions fixed here.
///
/// Both are asserted as real layout positions under simulated device insets,
/// not as "a SafeArea exists somewhere in the tree" — the latter passes even
/// when the SafeArea is nested where it does nothing.
void main() {
  // The parameterised groups below build AppTheme during collection, and the
  // themes resolve Google Fonts — which needs a live binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  // A modern handset: tall status bar, gesture bar at the bottom.
  const statusBar = 44.0;
  const gestureBar = 34.0;
  const screen = Size(393, 852);

  AuthBloc buildAuthBloc() {
    final repository = FakeAuthRepository();
    return AuthBloc(
      restoreSession: RestoreSessionUseCase(repository),
      validateSession: ValidateSessionUseCase(repository),
      login: LoginUseCase(repository),
      logout: LogoutUseCase(repository),
    );
  }

  Future<void> pumpWithInsets(
    WidgetTester tester, {
    required Widget child,
    required ThemeData theme,
    Widget Function(Widget)? wrap,
  }) async {
    await tester.binding.setSurfaceSize(screen);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final app = MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: statusBar, bottom: gestureBar),
            viewPadding: const EdgeInsets.only(
              top: statusBar,
              bottom: gestureBar,
            ),
          ),
          child: child,
        ),
      ),
    );

    await tester.pumpWidget(wrap == null ? app : wrap(app));
    await tester.pumpAndSettle();
  }

  group('drawer sign-out clears the system navigation bar', () {
    for (final mode in ['light', 'dark']) {
      testWidgets('sign out sits above the gesture bar ($mode)', (
        tester,
      ) async {
        final theme = mode == 'dark' ? AppTheme.dark : AppTheme.light;
        final authBloc = buildAuthBloc();
        addTearDown(authBloc.close);

        await pumpWithInsets(
          tester,
          theme: theme,
          wrap: (app) =>
              BlocProvider<AuthBloc>.value(value: authBloc, child: app),
          child: Scaffold(
            drawer: WmsAppDrawer(
              subtitle: 'Warehouse Operations',
              currentBottomIndex: 0,
              onNavigate: (_, __) {},
              items: const [
                WmsDrawerItem(
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  bottomIndex: 0,
                ),
                WmsDrawerItem(
                  label: 'Inventory',
                  icon: Icons.inventory_2_outlined,
                  bottomIndex: 1,
                ),
              ],
            ),
            body: const SizedBox.shrink(),
          ),
        );

        // Open the drawer.
        final scaffoldState = tester.firstState<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Measure the interactive row, not the glyph box: the text can clear
        // the bar while the 48dp touch target underneath it does not.
        final signOut = find.widgetWithText(WmsDrawerMenuTile, 'Sign out');
        expect(signOut, findsOneWidget);

        final tileBottom = tester.getRect(signOut).bottom;
        final safeBottom = screen.height - gestureBar;

        expect(
          tileBottom,
          lessThanOrEqualTo(safeBottom),
          reason:
              'The sign-out row must finish above the gesture bar; it '
              'ends at $tileBottom with the safe edge at $safeBottom',
        );
      });

      testWidgets(
        'navigation list scrolls without pushing sign out off ($mode)',
        (tester) async {
          final theme = mode == 'dark' ? AppTheme.dark : AppTheme.light;
          final authBloc = buildAuthBloc();
          addTearDown(authBloc.close);

          // Far more destinations than fit: the list must scroll inside its
          // Expanded slot rather than displacing the pinned footer.
          final many = [
            for (var i = 0; i < 24; i++)
              WmsDrawerItem(
                label: 'Destination $i',
                icon: Icons.circle_outlined,
                bottomIndex: i,
              ),
          ];

          await pumpWithInsets(
            tester,
            theme: theme,
            wrap: (app) =>
                BlocProvider<AuthBloc>.value(value: authBloc, child: app),
            child: Scaffold(
              drawer: WmsAppDrawer(
                subtitle: 'Warehouse Operations',
                currentBottomIndex: 0,
                onNavigate: (_, __) {},
                items: many,
              ),
              body: const SizedBox.shrink(),
            ),
          );

          final scaffoldState = tester.firstState<ScaffoldState>(
            find.byType(Scaffold),
          );
          scaffoldState.openDrawer();
          await tester.pumpAndSettle();

          final signOut = find.widgetWithText(WmsDrawerMenuTile, 'Sign out');
          expect(signOut, findsOneWidget);
          expect(
            tester.getRect(signOut).bottom,
            lessThanOrEqualTo(screen.height - gestureBar),
          );
          // The overflowing list is scrollable, so nothing is silently cut.
          expect(find.byType(ListView), findsOneWidget);
        },
      );
    }
  });

  group('products header clears the status bar', () {
    for (final mode in ['light', 'dark']) {
      testWidgets('title and Add Product start below the status bar ($mode)', (
        tester,
      ) async {
        final theme = mode == 'dark' ? AppTheme.dark : AppTheme.light;
        await pumpWithInsets(
          tester,
          theme: theme,
          child: Scaffold(
            body: Column(
              children: [
                ProductsMobileHeader(
                  canManage: true,
                  onAdd: () {},
                  onBack: () {},
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        );

        for (final finder in [
          find.text('Products'),
          find.text('Add Product'),
        ]) {
          expect(finder, findsOneWidget);
          expect(
            tester.getTopLeft(finder).dy,
            greaterThanOrEqualTo(statusBar),
            reason:
                'Header content must begin below the ${statusBar}dp '
                'status bar, not under the clock and battery icons',
          );
        }

        // The back affordance is a touch target, so it matters most of all.
        final back = find.byIcon(Icons.arrow_back_rounded);
        expect(back, findsOneWidget);
        expect(tester.getTopLeft(back).dy, greaterThanOrEqualTo(statusBar));
      });

      testWidgets('the header still paints behind the status bar ($mode)', (
        tester,
      ) async {
        final theme = mode == 'dark' ? AppTheme.dark : AppTheme.light;
        await pumpWithInsets(
          tester,
          theme: theme,
          child: Scaffold(
            body: Column(
              children: [
                ProductsMobileHeader(canManage: true, onAdd: () {}),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        );

        // Insetting content is only half the fix: the surface has to extend
        // under the status bar, or the inset shows as a bare strip.
        final headerTop = tester.getTopLeft(find.byType(ProductsMobileHeader));
        expect(
          headerTop.dy,
          0,
          reason:
              'The header surface should start at the screen edge and let '
              'SafeArea inset only its content',
        );
      });
    }
  });

  testWidgets('header height absorbs the inset rather than clipping content', (
    tester,
  ) async {
    // Same widget, with and without insets: the difference must be exactly the
    // status-bar height. If it is not, the content was clipped instead.
    Future<double> headerHeight(EdgeInsets padding) async {
      await tester.binding.setSurfaceSize(screen);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: padding, viewPadding: padding),
              child: Scaffold(
                body: Column(
                  children: [
                    ProductsMobileHeader(canManage: true, onAdd: () {}),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(ProductsMobileHeader)).height;
    }

    final bare = await headerHeight(EdgeInsets.zero);
    final inset = await headerHeight(const EdgeInsets.only(top: statusBar));

    expect(inset - bare, closeTo(statusBar, 0.5));
  });
}
