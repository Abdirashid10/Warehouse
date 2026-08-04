import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:logisticsmobile/features/notifications/presentation/widgets/notifications_enterprise_widgets.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

class AdminNotificationsPanel extends StatefulWidget {
  const AdminNotificationsPanel({
    super.key,
    required this.cubit,
    this.padding = true,
    this.sectioned = false,
  });

  final NotificationsCubit cubit;
  final bool padding;
  final bool sectioned;

  @override
  State<AdminNotificationsPanel> createState() => _AdminNotificationsPanelState();
}

class _AdminNotificationsPanelState extends State<AdminNotificationsPanel> {
  NotificationDisplayCategory _displayCategory = NotificationDisplayCategory.all;
  NotificationPriority? _priority;
  bool _unreadOnly = false;
  final Set<String> _archivedIds = {};

  bool get _useCommandCenterLayout =>
      _displayCategory == NotificationDisplayCategory.all &&
      _priority == null &&
      !_unreadOnly;

  void _archive(AppNotification notification) {
    setState(() => _archivedIds.add(notification.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archived "${notification.title}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<AppNotification> _visible(NotificationsListState data) {
    return filterNotificationsForDisplay(
      data: data,
      displayCategory: _displayCategory,
      priority: _priority,
      archivedIds: _archivedIds,
      unreadOnly: _unreadOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, ResourceState<NotificationsListState>>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state.isFailure && state.data == null) {
          return _buildScrollableBody(
            [
              SliverFillRemaining(
                hasScrollBody: false,
                child: WmsErrorState(
                  message: state.message ?? 'Failed to load notifications',
                  onRetry: widget.cubit.load,
                ),
              ),
            ],
          );
        }

        final data = state.data;
        if (data == null || state.isLoading) {
          return _buildScrollableBody(
            const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        if (data.items.isEmpty) {
          return _buildScrollableBody(
            [
              SliverFillRemaining(
                hasScrollBody: false,
                child: const _NotificationsEmptyView(),
              ),
            ],
          );
        }

        final horizontal = widget.padding ? AppSpacing.screenPadding : 0.0;
        final visible = _visible(data);

        return _buildScrollableBody(
          [
            SliverToBoxAdapter(
              child: NotificationsCommandCenterHeader(
                data: data,
                onMarkAllRead: widget.cubit.markAllRead,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                0,
                horizontal,
                AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  NotificationsFilterPanel(
                    displayCategory: _displayCategory,
                    priority: _priority,
                    data: data,
                    unreadOnly: _unreadOnly,
                    onUnreadOnlyChanged: (v) => setState(() => _unreadOnly = v),
                    onCategorySelected: (c) =>
                        setState(() => _displayCategory = c),
                    onPrioritySelected: (p) => setState(() => _priority = p),
                  ),
                  const SizedBox(height: NotificationUi.sectionGap),
                  ..._buildContent(data, visible),
                ]),
              ),
            ),
          ],
          showLoadingOverlay: state.isLoading,
        );
      },
    );
  }

  Widget _buildScrollableBody(
    List<Widget> slivers, {
    bool showLoadingOverlay = false,
  }) {
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    );

    final body = RefreshIndicator(
      onRefresh: widget.cubit.load,
      child: scrollView,
    );

    if (!showLoadingOverlay) return body;

    return Stack(
      children: [
        body,
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(minHeight: 2),
        ),
      ],
    );
  }

  List<Widget> _buildContent(
    NotificationsListState data,
    List<AppNotification> visible,
  ) {
    if (visible.isEmpty) {
      return [
        WmsEmptyStates.notifications(
          message: data.items.isEmpty
              ? null
              : 'No notifications match your current filters.',
        ),
      ];
    }

    if (_useCommandCenterLayout) {
      return _buildCommandCenterSections(data);
    }

    return _buildFilteredInbox(data, visible);
  }

  List<Widget> _buildCommandCenterSections(NotificationsListState data) {
    final critical = _notArchived(
      NotificationMetrics.criticalAlerts(data),
    );

    final sections = <Widget>[
      NotificationsCriticalSection(
        items: critical,
        data: data,
        onRead: widget.cubit.markAsRead,
        onArchive: _archive,
      ),
      if (critical.isNotEmpty) const SizedBox(height: NotificationUi.sectionGap),
      NotificationsEnterpriseSection(
        title: 'Inventory Alerts',
        subtitle: 'Stock, low inventory, and replenishment',
        category: NotificationCategoryFilter.inventory,
        items: _notArchived(data.inventoryItems),
        data: data,
        onRead: widget.cubit.markAsRead,
        onArchive: _archive,
      ),
      const SizedBox(height: NotificationUi.sectionGap),
      NotificationsEnterpriseSection(
        title: 'Task Alerts',
        subtitle: 'Assignments, deadlines, and updates',
        category: NotificationCategoryFilter.tasks,
        items: _notArchived(data.taskItems),
        data: data,
        onRead: widget.cubit.markAsRead,
        onArchive: _archive,
      ),
      const SizedBox(height: NotificationUi.sectionGap),
      NotificationsEnterpriseSection(
        title: 'Order Alerts',
        subtitle: 'Fulfillment, shipping, and delivery',
        category: NotificationCategoryFilter.orders,
        items: _notArchived(data.orderItems),
        data: data,
        onRead: widget.cubit.markAsRead,
        onArchive: _archive,
      ),
      const SizedBox(height: NotificationUi.sectionGap),
      NotificationsEnterpriseSection(
        title: 'Warehouse Alerts',
        subtitle: 'Capacity, location, and facility events',
        category: NotificationCategoryFilter.warehouses,
        items: _notArchived(data.warehouseItems),
        data: data,
        onRead: widget.cubit.markAsRead,
        onArchive: _archive,
      ),
      const SizedBox(height: NotificationUi.sectionGap),
      NotificationsEnterpriseSection(
        title: 'System Notifications',
        category: NotificationCategoryFilter.system,
        items: _notArchived(data.systemItems),
        data: data,
        onRead: widget.cubit.markAsRead,
        onArchive: _archive,
      ),
    ];

    return sections;
  }

  List<AppNotification> _notArchived(List<AppNotification> items) =>
      items.where((n) => !_archivedIds.contains(n.id)).toList();

  List<Widget> _buildFilteredInbox(
    NotificationsListState data,
    List<AppNotification> visible,
  ) {
    final sorted = sortNotificationsForDisplay(visible, data);
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: WmsDesignTokens.sectionAccentBarWidth,
              height: WmsDesignTokens.sectionAccentBarHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Filtered Alerts',
                style: WmsDesignTokens.sectionTitle(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                '${sorted.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ],
        ),
      ),
      for (final n in sorted)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: NotificationsEnterpriseCard(
            notification: n,
            isRead: data.isRead(n),
            onTap: () => widget.cubit.markAsRead(n),
            onMarkRead: () => widget.cubit.markAsRead(n),
            onArchive: () => _archive(n),
          ),
        ),
    ];
    return widgets;
  }
}

/// Centered empty notifications placeholder for the notifications feed.
class _NotificationsEmptyView extends StatelessWidget {
  const _NotificationsEmptyView();

  @override
  Widget build(BuildContext context) {
    return WmsEmptyStates.notifications();
  }
}
