import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_atoms.dart';
import 'package:logisticsmobile/features/admin/presentation/widgets/admin_premium_theme.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Severity of an operational alert, used for its banner colour and tag.
enum AlertSeverity { critical, warning, success, info }

/// Classifies a notification's severity from its type and category.
///
/// Keyword-ordered so a failure never lands in a softer bucket than it
/// deserves: destructive and failure wording is checked before "pending" or
/// generic informational terms.
AlertSeverity alertSeverityOf(AppNotification notification) {
  final text =
      '${notification.type} ${notification.category ?? ''} ${notification.title}'
          .toLowerCase();

  bool has(List<String> keywords) => keywords.any(text.contains);

  if (has(['critical', 'error', 'fail', 'out_of_stock', 'out of stock',
      'overdue', 'expired', 'breach', 'reject'])) {
    return AlertSeverity.critical;
  }
  if (has(['warning', 'low_stock', 'low stock', 'expiring', 'due', 'delay',
      'pending', 'threshold'])) {
    return AlertSeverity.warning;
  }
  if (has(['complete', 'delivered', 'received', 'success', 'approved',
      'resolved'])) {
    return AlertSeverity.success;
  }
  return AlertSeverity.info;
}

/// Alerts tab — severity-tagged notification banners.
class AdminAlertsPanel extends StatefulWidget {
  const AdminAlertsPanel({
    super.key,
    required this.cubit,
    this.padding = false,
  });

  final NotificationsCubit cubit;
  final bool padding;

  @override
  State<AdminAlertsPanel> createState() => _AdminAlertsPanelState();
}

class _AdminAlertsPanelState extends State<AdminAlertsPanel> {
  AlertSeverity? _severityFilter;
  bool _unreadOnly = false;

  List<AppNotification> _visible(NotificationsListState data) {
    return data.items.where((notification) {
      if (_unreadOnly && data.isRead(notification)) return false;
      if (_severityFilter != null &&
          alertSeverityOf(notification) != _severityFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _severityFilter = null;
      _unreadOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    return BlocBuilder<NotificationsCubit, ResourceState<NotificationsListState>>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state.isLoading && state.data == null) {
          return const WmsListSkeleton();
        }

        final data = state.data;
        if (data == null) {
          return WmsErrorState(
            message: state.message ?? 'Failed to load alerts',
            onRetry: widget.cubit.load,
          );
        }

        if (data.items.isEmpty) {
          return const AdminEmptyState(
            icon: Icons.notifications_off_rounded,
            title: 'No alerts',
            message:
                'Operational alerts will land here as the platform detects '
                'stock, task and order events that need attention.',
          );
        }

        final visible = _visible(data);
        final unread = data.effectiveUnreadCount;
        final counts = <AlertSeverity, int>{};
        for (final notification in data.items) {
          final severity = alertSeverityOf(notification);
          counts[severity] = (counts[severity] ?? 0) + 1;
        }

        return AdminTabScroll(
          padding: widget.padding,
          children: [
            AdminSectionIntro(
              eyebrow: 'Operations',
              title: 'Alert Center',
              subtitle: '$unread unread of ${data.items.length} alerts',
              trailing: AdminGlowBadge(
                icon: Icons.notifications_active_rounded,
                color: unread > 0 ? palette.coral : palette.brand,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SeverityFilterBar(
              counts: counts,
              selected: _severityFilter,
              unreadOnly: _unreadOnly,
              unreadCount: unread,
              onSeverity: (severity) => setState(
                () => _severityFilter =
                    _severityFilter == severity ? null : severity,
              ),
              onUnreadOnly: () => setState(() => _unreadOnly = !_unreadOnly),
            ),
            if (unread > 0) ...[
              const SizedBox(height: AppSpacing.md),
              AdminGradientButton(
                icon: Icons.done_all_rounded,
                label: 'Mark all as read',
                expanded: true,
                onPressed: widget.cubit.markAllRead,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (visible.isEmpty)
              AdminEmptyState(
                icon: Icons.filter_alt_off_rounded,
                title: 'No matching alerts',
                message:
                    'No alerts match the current severity or unread filters.',
                actionLabel: 'Reset filters',
                actionIcon: Icons.restart_alt_rounded,
                onAction: _resetFilters,
              )
            else
              ...visible.map(
                (notification) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
                  child: AdminAlertBanner(
                    notification: notification,
                    isRead: data.isRead(notification),
                    onMarkRead: () => widget.cubit.markAsRead(notification),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A single alert rendered as a severity-tagged banner.
class AdminAlertBanner extends StatelessWidget {
  const AdminAlertBanner({
    super.key,
    required this.notification,
    required this.isRead,
    this.onMarkRead,
  });

  final AppNotification notification;
  final bool isRead;
  final VoidCallback? onMarkRead;

  static ({IconData icon, String label}) _spec(AlertSeverity severity) =>
      switch (severity) {
        AlertSeverity.critical => (
            icon: Icons.error_rounded,
            label: 'Critical',
          ),
        AlertSeverity.warning => (
            icon: Icons.warning_amber_rounded,
            label: 'Warning',
          ),
        AlertSeverity.success => (
            icon: Icons.check_circle_rounded,
            label: 'Resolved',
          ),
        AlertSeverity.info => (
            icon: Icons.info_rounded,
            label: 'Info',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);
    final colors = palette.colors;
    final severity = alertSeverityOf(notification);
    final spec = _spec(severity);

    final accent = switch (severity) {
      AlertSeverity.critical => palette.coral,
      AlertSeverity.warning => palette.amber,
      AlertSeverity.success => palette.emerald,
      AlertSeverity.info => palette.cobalt,
    };

    return AdminGlassCard(
      accentStrip: accent,
      onTap: isRead ? null : onMarkRead,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminGlowBadge(icon: spec.icon, color: accent, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.cardTitle(context).copyWith(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: palette.coral,
                              shape: BoxShape.circle,
                              boxShadow: palette.glow(
                                palette.coral,
                                opacity: 0.55,
                                blur: 6,
                                dy: 0,
                                spread: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.supporting(context).copyWith(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              AdminStatusChip(
                label: spec.label,
                color: accent,
                icon: spec.icon,
                dense: true,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: AdminStatusChip(
                  label: notification.categoryLabel,
                  color: palette.slate,
                  dense: true,
                ),
              ),
              const Spacer(),
              if (notification.createdAt != null)
                Text(
                  WmsFormatters.relativeTime(notification.createdAt),
                  maxLines: 1,
                  style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: colors.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeverityFilterBar extends StatelessWidget {
  const _SeverityFilterBar({
    required this.counts,
    required this.selected,
    required this.unreadOnly,
    required this.unreadCount,
    required this.onSeverity,
    required this.onUnreadOnly,
  });

  final Map<AlertSeverity, int> counts;
  final AlertSeverity? selected;
  final bool unreadOnly;
  final int unreadCount;
  final ValueChanged<AlertSeverity> onSeverity;
  final VoidCallback onUnreadOnly;

  @override
  Widget build(BuildContext context) {
    final palette = AdminPalette.of(context);

    Color accentFor(AlertSeverity severity) => switch (severity) {
          AlertSeverity.critical => palette.coral,
          AlertSeverity.warning => palette.amber,
          AlertSeverity.success => palette.emerald,
          AlertSeverity.info => palette.cobalt,
        };

    String labelFor(AlertSeverity severity) => switch (severity) {
          AlertSeverity.critical => 'Critical',
          AlertSeverity.warning => 'Warning',
          AlertSeverity.success => 'Resolved',
          AlertSeverity.info => 'Info',
        };

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        children: [
          AdminFilterPill(
            label: 'Unread',
            count: unreadCount,
            icon: Icons.mark_email_unread_rounded,
            accent: palette.coral,
            selected: unreadOnly,
            onTap: onUnreadOnly,
          ),
          for (final severity in AlertSeverity.values)
            if ((counts[severity] ?? 0) > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              AdminFilterPill(
                label: labelFor(severity),
                count: counts[severity],
                accent: accentFor(severity),
                selected: selected == severity,
                onTap: () => onSeverity(severity),
              ),
            ],
        ],
      ),
    );
  }
}
