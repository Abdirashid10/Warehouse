import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_activity_timeline.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class AdminActivityPanel extends StatelessWidget {
  const AdminActivityPanel({super.key, required this.activities});

  final List<AuditActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Center(
        child: WmsEmptyState(
          title: 'No recent activity',
          message: 'System events will appear here as users perform warehouse operations.',
          icon: Icons.timeline_outlined,
        ),
      );
    }

    final entries = activities.take(25).map((a) {
      final mapped = WmsTimelineMapper.fromActionText(
        action: '${a.action} ${a.details}',
        userName: a.userName,
        relativeTime: WmsFormatters.relativeTime(a.occurredAt),
      );
      return mapped;
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
      children: [
        Text(
          'Activity timeline',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Latest system activities — inventory, orders, tasks, and user actions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        WmsActivityTimeline(
          title: 'System feed',
          entries: entries,
          maxItems: 25,
        ),
      ],
    );
  }
}
