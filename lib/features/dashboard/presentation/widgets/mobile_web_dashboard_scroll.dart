import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/features/dashboard/domain/entities/control_center_data.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/control_center_header.dart';
import 'package:logisticsmobile/features/dashboard/presentation/widgets/warehouse_control_center_body.dart';

/// Web-parity dashboard — flat [CustomScrollView] + [SliverList]
/// (no nested Column scroll).
class MobileWebDashboardScroll extends StatelessWidget {
  const MobileWebDashboardScroll({
    super.key,
    required this.data,
    required this.onRefresh,
    required this.inventoryRoute,
    required this.tasksRoute,
    required this.ordersRoute,
    required this.notificationsRoute,
    required this.stockOpsRoute,
    required this.forAdmin,
    required this.lastSyncedAt,
    required this.isLoading,
    this.reportsRoute,
    this.auditRoute,
    this.warningMessage,
  });

  final ControlCenterData data;
  final Future<void> Function() onRefresh;
  final String inventoryRoute;
  final String tasksRoute;
  final String ordersRoute;
  final String notificationsRoute;
  final String stockOpsRoute;
  final String? reportsRoute;
  final String? auditRoute;
  final bool forAdmin;
  final DateTime? lastSyncedAt;
  final bool isLoading;
  final String? warningMessage;

  @override
  Widget build(BuildContext context) {
    final body = WarehouseControlCenterBody(
      data: data,
      inventoryRoute: inventoryRoute,
      tasksRoute: tasksRoute,
      ordersRoute: ordersRoute,
      notificationsRoute: notificationsRoute,
      stockOpsRoute: stockOpsRoute,
      reportsRoute: reportsRoute,
      auditRoute: auditRoute,
    );

    final sections = body.buildSections(context);
    const gap = MobileUi.dashboardSectionGap;

    final children = <Widget>[
      if (warningMessage != null) ...[
        _WarningBanner(message: warningMessage!),
        const SizedBox(height: gap),
      ],
      if (isLoading)
        const Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: LinearProgressIndicator(minHeight: 2),
        ),
      ControlCenterHeader(
        data: data,
        forAdmin: forAdmin,
        lastSyncedAt: lastSyncedAt,
        isLoading: isLoading,
        embeddedInShell: true,
      ),
      const SizedBox(height: gap),
      for (var i = 0; i < sections.length; i++) ...[
        sections[i],
        if (i < sections.length - 1) const SizedBox(height: gap),
      ],
      const SizedBox(height: gap),
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(MobileUi.dashboardScreenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate(children),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .errorContainer
          .withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
