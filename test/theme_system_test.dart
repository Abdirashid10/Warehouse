import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/settings/theme_preferences.dart';
import 'package:logisticsmobile/core/theme/app_theme.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contract for the app-wide light/dark theme system.
///
/// Three things are pinned here:
///  1. the UI reads semantic tokens, not the light-only static palette,
///  2. text clears WCAG AA against the surface it actually sits on, in both
///     modes,
///  3. the app follows the OS by default and persists an explicit override.
void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // Contrast helpers (WCAG 2.1 relative luminance)
  // ───────────────────────────────────────────────────────────────────────────

  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Resolves the token set for a brightness through a real widget tree, so the
  /// values under test are exactly what the app paints.
  Future<WmsUiColors> paletteFor(WidgetTester tester, ThemeData theme) async {
    late WmsUiColors colors;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            colors = WmsUiColors.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    // MaterialApp animates between themes, so the first frame after a swap
    // still carries the previous ThemeData. Settle before reading tokens.
    await tester.pumpAndSettle();
    return colors;
  }

  group('semantic tokens', () {
    testWidgets('dark mode uses a soft dark surface, never pure black',
        (tester) async {
      final colors = await paletteFor(tester, AppTheme.dark);

      expect(colors.isDark, isTrue);
      for (final surface in [
        colors.background,
        colors.surface,
        colors.surfaceElevated,
      ]) {
        expect(
          surface,
          isNot(const Color(0xFF000000)),
          reason: 'Pure black raises eye strain and kills elevation cues',
        );
        // Comfortably dark, but still a slate rather than a void.
        expect(luminance(surface), lessThan(0.08));
        expect(luminance(surface), greaterThan(0.002));
      }
    });

    testWidgets('elevation reads: cards sit above the base layer',
        (tester) async {
      final dark = await paletteFor(tester, AppTheme.dark);
      expect(
        luminance(dark.surface),
        greaterThan(luminance(dark.background)),
        reason: 'A dark card must be lighter than the page behind it',
      );
      expect(
        luminance(dark.surfaceElevated),
        greaterThan(luminance(dark.surface)),
        reason: 'The elevated layer must read above the card',
      );

      final light = await paletteFor(tester, AppTheme.light);
      expect(
        luminance(light.surface),
        greaterThan(luminance(light.background)),
        reason: 'A light card is white against a tinted page',
      );
    });

    testWidgets('both modes carry a distinct token set', (tester) async {
      final light = await paletteFor(tester, AppTheme.light);
      final dark = await paletteFor(tester, AppTheme.dark);

      expect(light.background, isNot(dark.background));
      expect(light.textPrimary, isNot(dark.textPrimary));
      expect(light.border, isNot(dark.border));
    });
  });

  group('WCAG AA contrast', () {
    // 4.5:1 for body copy, 3:1 for large/secondary text and UI boundaries.
    const bodyMinimum = 4.5;
    const largeMinimum = 3.0;

    testWidgets('primary text clears AA on every surface, both modes',
        (tester) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final colors = await paletteFor(tester, theme);
        final mode = colors.isDark ? 'dark' : 'light';

        for (final entry in {
          'background': colors.background,
          'surface': colors.surface,
          'surfaceElevated': colors.surfaceElevated,
        }.entries) {
          expect(
            contrast(colors.textPrimary, entry.value),
            greaterThanOrEqualTo(bodyMinimum),
            reason: 'textPrimary on ${entry.key} ($mode) is below AA',
          );
        }
      }
    });

    testWidgets('secondary and tertiary text clear the large-text floor',
        (tester) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final colors = await paletteFor(tester, theme);
        final mode = colors.isDark ? 'dark' : 'light';

        for (final entry in {
          'textSecondary': colors.textSecondary,
          'textTertiary': colors.textTertiary,
        }.entries) {
          expect(
            contrast(entry.value, colors.surface),
            greaterThanOrEqualTo(largeMinimum),
            reason: '${entry.key} on surface ($mode) is below the 3:1 floor',
          );
        }
      }
    });

    testWidgets('status colours stay legible on their own muted fills',
        (tester) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final colors = await paletteFor(tester, theme);
        final mode = colors.isDark ? 'dark' : 'light';

        final pairs = <String, (Color ink, Color fill)>{
          'success': (colors.success, colors.successMuted),
          'warning': (colors.warning, colors.warningMuted),
          'error': (colors.error, colors.errorMuted),
          'info': (colors.info, colors.infoMuted),
        };

        for (final entry in pairs.entries) {
          final (ink, fill) = entry.value;
          expect(
            contrast(ink, fill),
            greaterThanOrEqualTo(largeMinimum),
            reason: '${entry.key} ink on its muted chip ($mode) is below 3:1',
          );
        }
      }
    });
  });

  group('theme transitions', () {
    test('the extension interpolates every visual field', () {
      const t = 0.5;
      final mid = WmsThemeExtension.light.lerp(WmsThemeExtension.dark, t);

      // A field that snaps would equal one endpoint exactly at t = 0.5.
      expect(mid.cardBackground, isNot(WmsThemeExtension.light.cardBackground));
      expect(mid.cardBackground, isNot(WmsThemeExtension.dark.cardBackground));

      // Gradients and shadows are the largest surfaces on screen; if they snap
      // while flat colours glide, the switch flashes.
      expect(
        mid.brandGradient.colors.first,
        isNot(WmsThemeExtension.light.brandGradient.colors.first),
      );
      expect(
        mid.cardShadow.first.color,
        isNot(WmsThemeExtension.light.cardShadow.first.color),
      );
    });
  });

  group('mode persistence', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a fresh install follows the system', () async {
      final prefs = ThemePreferences(await SharedPreferences.getInstance());

      expect(prefs.hasExplicitPreference, isFalse);
      expect(prefs.themePreference, AppThemePreference.system);
      expect(themeModeFromPreference(prefs.themePreference), ThemeMode.system);
    });

    test('an explicit choice is persisted and read back', () async {
      final prefs = ThemePreferences(await SharedPreferences.getInstance());

      await prefs.setThemePreference(AppThemePreference.dark);

      final reloaded = ThemePreferences(await SharedPreferences.getInstance());
      expect(reloaded.hasExplicitPreference, isTrue);
      expect(reloaded.themePreference, AppThemePreference.dark);
      expect(themeModeFromPreference(reloaded.themePreference), ThemeMode.dark);
    });

    test('every preference maps to a mode', () {
      expect(themeModeFromPreference(AppThemePreference.system),
          ThemeMode.system);
      expect(themeModeFromPreference(AppThemePreference.light), ThemeMode.light);
      expect(themeModeFromPreference(AppThemePreference.dark), ThemeMode.dark);
    });
  });

  group('no theme-blind colours in UI code', () {
    // Roles that invert between modes. A literal from the light-only palette in
    // UI code means a white card or near-black text on a dark background.
    final invertingRoles = RegExp(
      r'AppColors\.(surface|surfaceVariant|background|border|divider'
      r'|textPrimary|textSecondary|textTertiary'
      r'|primaryLight|accentLight|successLight|warningLight|errorLight'
      r'|infoLight|tasksLight|outboundLight|expiredLight|processingLight)\b',
    );

    /// The token layer is where literals are *supposed* to live.
    bool isTokenLayer(String path) =>
        path.contains('/core/theme/') || path.contains(r'\core\theme\');

    List<File> uiSources() {
      final dir = Directory('lib');
      if (!dir.existsSync()) return const [];
      return dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !isTokenLayer(f.path))
          .toList();
    }

    test('UI code never reads an inverting role from the static palette', () {
      final offenders = <String>[];

      for (final file in uiSources()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (invertingRoles.hasMatch(lines[i])) {
            offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'These read a light-mode literal that cannot adapt. Use '
            'WmsUiColors.of(context) instead:\n${offenders.join('\n')}',
      );
    });

    test('the data layer never chooses a colour', () {
      // A colour picked while parsing JSON is frozen to whichever brightness
      // was active at parse time and cannot follow a mode switch. Data layers
      // describe *what* a series is; widgets decide how it looks.
      final offenders = <String>[];
      final dir = Directory('lib');
      if (!dir.existsSync()) return;

      final dataSources = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) =>
              f.path.contains('/data/') || f.path.contains(r'\data\'));

      final paints = RegExp(
        r'\b(Color\(0x|Colors\.|AppColors\.)',
      );

      for (final file in dataSources) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (paints.hasMatch(lines[i])) {
            offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Data layers must carry a semantic role, not a colour:\n'
            '${offenders.join('\n')}',
      );
    });

    test('UI code does not paint raw white or black as a surface', () {
      // Deliberately narrow, and only the properties that are unambiguously a
      // surface. A bare `color:` is not included: white *ink* on a brand
      // gradient or a filled button is correct and theme-independent, and a
      // guard that flags those would be noise and get deleted.
      final rawSurface = RegExp(
        r'(backgroundColor|fillColor|surfaceTintColor|scaffoldBackgroundColor)'
        r'\s*:\s*Colors\.(white|black)\s*[,)]',
      );
      final offenders = <String>[];

      for (final file in uiSources()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (rawSurface.hasMatch(lines[i])) {
            offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Raw surface fills cannot adapt to the theme:\n'
            '${offenders.join('\n')}',
      );
    });
  });
}
