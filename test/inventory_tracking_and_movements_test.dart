import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logisticsmobile/features/inventory/presentation/pages/inventory_tracking_screen.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/pages/stock_movements_screen.dart';

void main() {
  testWidgets('inventory tracking screen renders stock summary and warehouse list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InventoryTrackingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Inventory Tracking'), findsOneWidget);
    expect(find.text('North Hub'), findsOneWidget);
    expect(find.text('Low Stock'), findsWidgets);
  });

  testWidgets('stock movements screen renders movement history and action button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: StockMovementsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Stock Movements'), findsWidgets);
    expect(find.text('Transfer to East Dock'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
