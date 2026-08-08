import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logisticsmobile/core/settings/theme_preferences.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/features/profile/domain/entities/user_profile.dart';
import 'package:logisticsmobile/features/profile/presentation/widgets/profile_enterprise_widgets.dart';
import 'package:logisticsmobile/widgets/wms/wms_metric_pill.dart';

/// Layout contract for the redesigned Profile screen.
void main() {
  // Widget tests must never reach the network.
  GoogleFonts.config.allowRuntimeFetching = false;

  const widths = <double>[320, 360, 375, 393, 412, 430, 480];
  const textScales = <double>[1.0, 1.2, 1.3];

  final profile = UserProfile(
    fullName: 'Ahmed Hassan Mohamed',
    email: 'ahmed.hassan@logistics.example',
    role: 'Admin',
    username: 'ahmed.hassan',
    phone: '+252 61 234 5678',
    permissions: const ['task.view', 'order.edit', 'inventory.move'],
    lastActiveAt: DateTime(2026, 8, 5),
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

    await tester.binding.setSurfaceSize(Size(width, 1400));
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

  Widget header({String warehouse = 'Central Distribution Center — North Bay'}) =>
      ProfileCommandCenterHeader(
        displayName: 'Ahmed Hassan Mohamed',
        roleLabel: 'Admin',
        warehouseLabel: warehouse,
        accountStatus: 'Active',
        username: 'ahmed.hassan',
      );

  Widget infoSection() => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: ProfileAccountInfoSection(
          email: 'ahmed.hassan@logistics.example',
          roleLabel: 'Admin',
          warehouseLabel: 'Central Distribution Center — North Bay',
          lastLogin: ProfileMetrics.lastLoginLabel(profile),
          phone: profile.phone,
        ),
      );

  group('ProfileCommandCenterHeader', () {
    for (final width in widths) {
      for (final scale in textScales) {
        testWidgets('no overflow at ${width.toInt()}dp @ ${scale}x',
            (tester) async {
          final overflows = await pump(
            tester,
            width: width,
            textScale: scale,
            child: header(),
          );
          expect(overflows, isEmpty, reason: overflows.join('\n'));
        });
      }
    }

    testWidgets('badges stay on one scrollable line', (tester) async {
      await pump(tester, width: 320, textScale: 1.0, child: header());

      // A single horizontal strip, not a Wrap that can run onto extra rows.
      final strip = find.descendant(
        of: find.byType(ProfileCommandCenterHeader),
        matching: find.byType(ListView),
      );
      expect(strip, findsOneWidget);
      expect(tester.getSize(strip).height, lessThanOrEqualTo(26.0));
    });

    testWidgets('a very long warehouse name does not break the hero',
        (tester) async {
      final overflows = await pump(
        tester,
        width: 320,
        textScale: 1.0,
        child: header(
          warehouse: 'Central Distribution and Consolidation Facility, '
              'North Bay, Building 14, Dock 7',
        ),
      );
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });

    testWidgets('name and handle stay single-line', (tester) async {
      await pump(tester, width: 320, textScale: 1.0, child: header());

      for (final text in ['Ahmed Hassan Mohamed', '@ahmed.hassan']) {
        final widget = tester.widget<Text>(find.text(text));
        expect(widget.maxLines, 1, reason: '$text should be single-line');
        expect(widget.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('renders in dark theme without overflow', (tester) async {
      final overflows = await pump(
        tester,
        width: 360,
        textScale: 1.2,
        theme: AppTheme.dark,
        child: header(),
      );
      expect(overflows, isEmpty, reason: overflows.join('\n'));
    });
  });

  group('ProfileAccountStatsStrip', () {
    testWidgets('four stats occupy one strip row', (tester) async {
      await pump(
        tester,
        width: 393,
        textScale: 1.0,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ProfileAccountStatsStrip(profile: profile),
        ),
      );

      expect(
        tester.getSize(find.byType(ProfileAccountStatsStrip)).height,
        WmsMetricPillBar.height,
      );
      expect(
        tester.widget<WmsMetricPillBar>(find.byType(WmsMetricPillBar)).metrics,
        hasLength(4),
      );
    });

    for (final width in [320.0, 360.0, 430.0]) {
      testWidgets('no overflow at ${width.toInt()}dp', (tester) async {
        final overflows = await pump(
          tester,
          width: width,
          textScale: 1.3,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ProfileAccountStatsStrip(profile: profile),
          ),
        );
        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }
  });

  group('ProfileActionTile', () {
    testWidgets('rows are compact list-height, not KPI-height',
        (tester) async {
      await pump(tester, width: 393, textScale: 1.0, child: infoSection());

      final heights = find
          .byType(ProfileActionTile)
          .evaluate()
          .map((e) => e.size!.height)
          .toList();
      expect(heights, isNotEmpty);
      for (final h in heights) {
        // A 16dp pad around a 34dp glyph gave a 66dp icon box alone.
        expect(h, lessThan(64), reason: 'tile too tall: $h');
      }
    });

    testWidgets('tiles in a section share one height', (tester) async {
      await pump(tester, width: 393, textScale: 1.0, child: infoSection());

      final heights = find
          .byType(ProfileActionTile)
          .evaluate()
          .map((e) => e.size!.height)
          .toSet();
      expect(
        heights,
        hasLength(1),
        reason: 'Uneven tiles come from subtitles wrapping to two lines',
      );
    });

    testWidgets('long values ellipsize rather than wrap', (tester) async {
      await pump(
        tester,
        width: 320,
        textScale: 1.0,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ProfileSettingsSection(
            title: 'Account Information',
            children: const [
              ProfileActionTile(
                icon: Icons.mail_outline_rounded,
                title: 'Email',
                subtitle: 'a.very.long.mailbox.name@logistics.example.com',
                showChevron: false,
              ),
            ],
          ),
        ),
      );

      final subtitle = tester.widget<Text>(
        find.text('a.very.long.mailbox.name@logistics.example.com'),
      );
      expect(subtitle.maxLines, 1);
      expect(subtitle.overflow, TextOverflow.ellipsis);
    });

    for (final width in [320.0, 360.0, 393.0]) {
      testWidgets('section has no overflow at ${width.toInt()}dp',
          (tester) async {
        final overflows = await pump(
          tester,
          width: width,
          textScale: 1.3,
          child: infoSection(),
        );
        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }
  });

  group('ProfilePreferencesSection', () {
    Widget prefs() => Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ProfilePreferencesSection(
            themePreference: AppThemePreference.system,
            pushNotifications: true,
            language: 'English',
            onThemeChanged: (_) {},
            onPushNotificationsChanged: (_) {},
            onLanguageChanged: (_) {},
          ),
        );

    testWidgets('exposes an interactive notifications toggle', (tester) async {
      await pump(tester, width: 393, textScale: 1.0, child: prefs());
      expect(find.byType(Switch), findsWidgets);
    });

    for (final width in [320.0, 393.0]) {
      testWidgets('no overflow at ${width.toInt()}dp', (tester) async {
        final overflows = await pump(
          tester,
          width: width,
          textScale: 1.2,
          child: prefs(),
        );
        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }
  });
}
