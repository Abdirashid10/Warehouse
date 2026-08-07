import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/widgets/app_button.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

/// Pins the two defects fixed here so they cannot silently return.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, {ThemeData? theme}) async {
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('google_fonts')) return;
      previous?.call(d);
    };
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AppButton label contrast', () {
    testWidgets('primary label is pure white, not the themed dark color',
        (tester) async {
      await pump(
        tester,
        AppButton(label: 'Sign In', onPressed: () {}),
      );

      final text = tester.widget<Text>(find.text('Sign In'));
      expect(
        text.style?.color,
        const Color(0xFFFFFFFF),
        reason: 'Filled button labels must not inherit the dark on-surface '
            'color that TextTheme.apply() stamps onto labelLarge',
      );
    });

    testWidgets('secondary label is pure white too', (tester) async {
      await pump(
        tester,
        AppButton(label: 'Continue', variant: AppButtonVariant.secondary, onPressed: () {}),
      );
      expect(
        tester.widget<Text>(find.text('Continue')).style?.color,
        const Color(0xFFFFFFFF),
      );
    });

    testWidgets('primary label stays white in dark theme', (tester) async {
      await pump(
        tester,
        AppButton(label: 'Sign In', onPressed: () {}),
        theme: AppTheme.dark,
      );
      expect(
        tester.widget<Text>(find.text('Sign In')).style?.color,
        const Color(0xFFFFFFFF),
      );
    });

    testWidgets('outline keeps the themed on-surface label', (tester) async {
      await pump(
        tester,
        AppButton(label: 'Cancel', variant: AppButtonVariant.outline, onPressed: () {}),
      );
      expect(
        tester.widget<Text>(find.text('Cancel')).style?.color,
        isNot(const Color(0xFFFFFFFF)),
      );
    });

    testWidgets('long labels ellipsize rather than overflow', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 160,
          child: AppButton(
            label: 'Sign in with a very long label that will not fit',
            icon: Icons.login,
            onPressed: () {},
          ),
        ),
      );
      final text = tester.widget<Text>(
        find.text('Sign in with a very long label that will not fit'),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('disabled filled button does not force white on grey',
        (tester) async {
      // A disabled ElevatedButton paints a pale grey fill. White-on-grey would
      // be just as unreadable as the dark-on-blue this change fixes.
      await pump(tester, const AppButton(label: 'Sign In'));
      expect(
        tester.widget<Text>(find.text('Sign In')).style?.color,
        isNot(const Color(0xFFFFFFFF)),
      );
    });
  });

  group('AppCard accent rail clearance', () {
    /// Distance from the card's left edge to the start of its content.
    Future<double> leadingGap(
      WidgetTester tester, {
      required EdgeInsets padding,
      Color? accent,
    }) async {
      await pump(
        tester,
        AppCard(
          padding: padding,
          accentColor: accent,
          child: const Text('Welcome back, Admin', key: ValueKey('copy')),
        ),
      );
      final cardLeft = tester.getTopLeft(find.byType(AppCard)).dx;
      final textLeft = tester.getTopLeft(find.byKey(const ValueKey('copy'))).dx;
      return textLeft - cardLeft;
    }

    testWidgets('compact padding still clears the 3.5dp rail', (tester) async {
      // AppSpacing.xs (4dp) is what the executive header passes in compact
      // mode — it previously left content 0.5dp from the rail.
      final gap = await leadingGap(
        tester,
        padding: const EdgeInsets.all(AppSpacing.xs),
        accent: const Color(0xFF2563EB),
      );
      expect(gap, greaterThanOrEqualTo(12.0));
    });

    testWidgets('generous padding is not inflated by the rail', (tester) async {
      const padding = EdgeInsets.all(AppSpacing.lg);
      final withAccent = await leadingGap(
        tester,
        padding: padding,
        accent: const Color(0xFF2563EB),
      );
      final withoutAccent = await leadingGap(tester, padding: padding);
      expect(
        withAccent,
        withoutAccent,
        reason: 'Cards that already pad past the clearance must not shift',
      );
    });

    testWidgets('cards without an accent rail keep their own padding',
        (tester) async {
      final gap = await leadingGap(
        tester,
        padding: const EdgeInsets.all(AppSpacing.xs),
      );
      // No rail to clear, so no compensating inset is added.
      expect(gap, lessThan(12.0));
    });
  });
}
