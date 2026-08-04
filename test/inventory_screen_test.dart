import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/features/dashboard/presentation/pages/dashboard_screen.dart';

void main() {
  testWidgets('dashboard screen renders greeting, alerts and expiry summary', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good afternoon, there'), findsOneWidget);
    expect(find.text('Operational Alerts'), findsOneWidget);
    expect(find.text('Out Of Stock'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Expiry Tracking'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Expiry Tracking'), findsOneWidget);
  });
}
