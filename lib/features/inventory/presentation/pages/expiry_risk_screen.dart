import 'package:flutter/material.dart';
import 'package:logisticsmobile/features/inventory/presentation/pages/inventory_screen.dart';
import 'package:logisticsmobile/widgets/wms/wms_pushed_scaffold.dart';

/// Web-parity Expiry & Risk view — inventory filtered to expiry concerns.
class ExpiryRiskScreen extends StatelessWidget {
  const ExpiryRiskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WmsPushedScaffold(
      title: 'Expiry & Risk',
      body: InventoryScreen(initialStockFilter: 'expired'),
    );
  }
}
