import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/notifications/domain/entities/app_notification.dart';
import 'package:logisticsmobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:logisticsmobile/features/notifications/presentation/widgets/notifications_enterprise_widgets.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Web-parity notifications inbox — simple scrollable feed (bell dropdown style).
class NotificationsInboxPanel extends StatelessWidget {
  const NotificationsInboxPanel({super.key, required this.cubit});

  final NotificationsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, ResourceState<NotificationsListState>>(
      bloc: cubit,
      builder: (context, state) {
        if (state.isFailure && state.data == null) {
          return _scrollable(
            cubit,
            [
              SliverFillRemaining(
                hasScrollBody: false,
                child: WmsErrorState(
                  message: state.message ?? 'Failed to load notifications',
                  onRetry: cubit.load,
                ),
              ),
            ],
          );
        }

        final data = state.data;
        if (data == null || state.isLoading) {
          return _scrollable(
            cubit,
            const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        if (data.items.isEmpty) {
          return _scrollable(
            cubit,
            const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _InboxEmptyView(),
              ),
            ],
          );
        }

        final unread = data.effectiveUnreadCount;
        final sorted = sortNotificationsForDisplay(data.items, data);

        return _scrollable(
          cubit,
          [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unread > 0 ? '$unread unread' : 'All caught up',
                            style: WmsDesignTokens.supporting(context).copyWith(
                              color: WmsUiColors.of(context).textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unread > 0)
                      TextButton.icon(
                        onPressed: cubit.markAllRead,
                        icon: const Icon(Icons.done_all, size: WmsIconSizes.status),
                        label: const Text('Mark all read'),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.xxl,
              ),
              sliver: SliverList.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final notification = sorted[index];
                  return NotificationsInboxCard(
                    notification: notification,
                    isRead: data.isRead(notification),
                    onTap: () => cubit.markAsRead(notification),
                    onMarkRead: () => cubit.markAsRead(notification),
                  );
                },
              ),
            ),
          ],
          showLoadingOverlay: state.isLoading,
        );
      },
    );
  }

  Widget _scrollable(
    NotificationsCubit cubit,
    List<Widget> slivers, {
    bool showLoadingOverlay = false,
  }) {
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    );

    final body = RefreshIndicator(
      onRefresh: cubit.load,
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
}

class NotificationsInboxCard extends StatelessWidget {
  const NotificationsInboxCard({
    super.key,
    required this.notification,
    required this.isRead,
    required this.onTap,
    required this.onMarkRead,
  });

  final AppNotification notification;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final colors = WmsUiColors.of(context);
    final category = notification.categoryLabel;

    return AppCard(
      onTap: onTap,
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.primaryMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: WmsIconSizes.listLeading,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isRead ? FontWeight.w600 : FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _CategoryBadge(label: category),
                    if (!isRead) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: colors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (notification.message.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.body(context).copyWith(
                      color: wms.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: WmsIconSizes.status,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          WmsFormatters.relativeTime(notification.createdAt),
                          style: WmsDesignTokens.supportingDense(context).copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (notification.performedBy != null &&
                        notification.performedBy!.isNotEmpty)
                      Text(
                        'by ${notification.performedBy}',
                        style: WmsDesignTokens.supportingDense(context).copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    if (!isRead)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'UNREAD',
                          style: WmsDesignTokens.supportingDense(context).copyWith(
                            color: colors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: onMarkRead,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View',
                            style: WmsDesignTokens.supportingDense(context).copyWith(
                              color: colors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: WmsIconSizes.status,
                            color: colors.success,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.infoMuted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: WmsDesignTokens.supportingDense(context).copyWith(
          color: colors.info,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _InboxEmptyView extends StatelessWidget {
  const _InboxEmptyView();

  @override
  Widget build(BuildContext context) {
    return WmsEmptyStates.notifications();
  }
}
