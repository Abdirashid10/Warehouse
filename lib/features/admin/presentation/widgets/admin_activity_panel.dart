import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_atoms.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_theme.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_activity_stream.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_premium_atoms.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_premium_theme.dart';

/// System Activity tab — the platform-wide event feed.
///
/// Renders with the audit module's timeline components rather than a parallel
/// implementation: an event must look identical in the console and in the
/// standalone Audit Logs screen, or the two stop being cross-checkable.
class AdminActivityPanel extends StatelessWidget {
  const AdminActivityPanel({
    super.key,
    required this.activities,
    this.padding = false,
    this.maxItems = 25,
  });

  final List<AuditActivity> activities;
  final bool padding;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final adminPalette = AdminPalette.of(context);
    final auditPalette = AuditPalette.of(context);

    if (activities.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.timeline_rounded,
        title: 'No recent activity',
        message:
            'System events appear here as users perform warehouse operations.',
      );
    }

    final visible = activities.take(maxItems).toList();
    final groups = _groupByDay(visible);

    final feed = <Widget>[];
    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];
      feed.add(
        AuditDayDivider(label: group.label, count: group.activities.length),
      );

      for (var i = 0; i < group.activities.length; i++) {
        final activity = group.activities[i];
        final isLastOfAll =
            g == groups.length - 1 && i == group.activities.length - 1;

        feed.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
            child: AuditTimelineTile(
              accent: auditPalette.accentFor(
                AuditActionClassifier.classify(
                  activity.action,
                  activity.module,
                ).kind,
              ),
              isFirst: i == 0,
              isLast: isLastOfAll,
              card: AuditLogCard(activity: activity),
            ),
          ),
        );
      }
    }

    return AdminTabScroll(
      padding: padding,
      children: [
        AdminSectionIntro(
          eyebrow: 'Telemetry',
          title: 'System Activity',
          subtitle: 'Latest ${visible.length} events across every module',
          trailing: AdminGlowBadge(
            icon: Icons.timeline_rounded,
            color: adminPalette.brand,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...feed,
      ],
    );
  }

  static List<_DayGroup> _groupByDay(List<AuditActivity> activities) {
    final buckets = <DateTime?, List<AuditActivity>>{};

    for (final activity in activities) {
      final occurredAt = activity.occurredAt;
      final key = occurredAt == null
          ? null
          : DateTime(occurredAt.year, occurredAt.month, occurredAt.day);
      buckets.putIfAbsent(key, () => []).add(activity);
    }

    final dated = buckets.keys.whereType<DateTime>().toList()
      ..sort((a, b) => b.compareTo(a));

    return [
      for (final day in dated)
        _DayGroup(label: _dayLabel(day), activities: buckets[day]!),
      if (buckets.containsKey(null))
        _DayGroup(label: 'Undated', activities: buckets[null]!),
    ];
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return AuditStamp.date(day);
  }
}

class _DayGroup {
  const _DayGroup({required this.label, required this.activities});

  final String label;
  final List<AuditActivity> activities;
}
