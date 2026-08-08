import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:logisticsmobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_quick_actions.dart';

/// Admin enterprise dashboard header — greeting, clock, role badge, quick actions.
class AdminEnterpriseDashboardHeader extends StatelessWidget {
  const AdminEnterpriseDashboardHeader({
    super.key,
    this.subtitle = 'Warehouse operations overview',
    this.roleLabel = 'Administrator',
    this.displayName,
    this.lastSyncedAt,
    this.showLoadingBar = false,
    required this.quickActions,
  });

  final String subtitle;
  final String roleLabel;
  final String? displayName;
  final DateTime? lastSyncedAt;
  final bool showLoadingBar;
  final List<WmsQuickAction> quickActions;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final primary = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();
    final topInset = MediaQuery.paddingOf(context).top;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, auth) {
        final user = auth.user;
        final fullName = displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : (user?.fullName ?? user?.email ?? 'Administrator');
        final firstName = fullName.split(RegExp(r'\s+')).first;
        final role = roleLabel.isNotEmpty ? roleLabel : (user?.role.label ?? 'Administrator');
        final initials = user?.initials ??
            (firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : 'A');

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md + topInset,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          child: AppCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${WmsFormatters.greeting()}, $firstName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.pageTitle(context).copyWith(
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.body(context).copyWith(
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _DateTimeWidget(now: now),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _RoleBadge(label: role, initials: initials),
                    if (lastSyncedAt != null)
                      _MetaChip(
                        icon: Icons.sync_rounded,
                        label: 'Synced ${WmsFormatters.relativeTime(lastSyncedAt)}',
                      ),
                    FilledButton.icon(
                      onPressed: () => _showQuickActions(context),
                      icon: Icon(Icons.bolt_rounded, size: WmsIconSizes.actionButton),
                      label: const Text('Quick Actions'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ],
                ),
                if (showLoadingBar) ...[
                  const SizedBox(height: AppSpacing.md),
                  LinearProgressIndicator(
                    minHeight: 2,
                    color: primary,
                    backgroundColor: wms.primaryLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            child: WmsQuickActionsSection(
              title: 'Quick Actions',
              compact: true,
              premium: true,
              showSubtitle: false,
              actions: quickActions,
            ),
          ),
        );
      },
    );
  }
}

class _DateTimeWidget extends StatelessWidget {
  const _DateTimeWidget({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: wms.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: wms.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('h:mm a').format(now),
            style: WmsDesignTokens.metricValue(context).copyWith(fontSize: 18),
          ),
          Text(
            DateFormat('EEE, MMM d, yyyy').format(now),
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: wms.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.initials});

  final String label;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: primary.withValues(alpha: 0.15),
            child: Text(
              initials,
              style: WmsDesignTokens.supporting(context).copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: WmsDesignTokens.supporting(context).copyWith(
              color: primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: wms.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: wms.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: WmsIconSizes.status, color: wms.textSecondary),
          const SizedBox(width: WmsIconSizes.iconLabelGap),
          Text(label, style: WmsDesignTokens.supportingDense(context)),
        ],
      ),
    );
  }
}

List<WmsQuickAction> adminDashboardQuickActions({
  required String stockOpsRoute,
  required String tasksRoute,
  required String ordersRoute,
  String? reportsRoute,
  required BuildContext context,
}) {
  return [
    WmsQuickAction(
      label: 'Receive',
      icon: Icons.download_rounded,
      onTap: () {
        Navigator.pop(context);
        context.push(stockOpsRoute);
      },
    ),
    WmsQuickAction(
      label: 'Dispatch',
      icon: Icons.upload_rounded,
      onTap: () {
        Navigator.pop(context);
        context.push(stockOpsRoute);
      },
    ),
    WmsQuickAction(
      label: 'Transfer',
      icon: Icons.swap_horiz_rounded,
      onTap: () {
        Navigator.pop(context);
        context.push(stockOpsRoute);
      },
    ),
    WmsQuickAction(
      label: 'Tasks',
      icon: Icons.assignment_outlined,
      onTap: () {
        Navigator.pop(context);
        context.push(tasksRoute);
      },
    ),
    WmsQuickAction(
      label: 'Orders',
      icon: Icons.shopping_cart_outlined,
      onTap: () {
        Navigator.pop(context);
        context.go(ordersRoute);
      },
    ),
    if (reportsRoute != null)
      WmsQuickAction(
        label: 'Reports',
        icon: Icons.assessment_outlined,
        onTap: () {
          Navigator.pop(context);
          context.push(reportsRoute);
        },
      ),
  ];
}
