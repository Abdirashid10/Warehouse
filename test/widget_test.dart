import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/core/constants/app_constants.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/widgets/loading_indicator.dart';

void main() {
  testWidgets('Splash branding widgets render', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.splashGradient),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warehouse_rounded, size: 48, color: Colors.white),
                SizedBox(height: AppSpacing.xxl),
                Text(
                  AppConstants.appName,
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: AppSpacing.xxxl),
                LoadingIndicator(size: 28, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Logistics WMS'), findsOneWidget);
    expect(find.text('Enterprise Warehouse Operations'), findsOneWidget);
  });
}
