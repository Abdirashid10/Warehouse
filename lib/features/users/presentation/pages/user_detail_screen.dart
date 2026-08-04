import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/users/domain/entities/wms_user.dart';
import 'package:logisticsmobile/features/users/presentation/widgets/users_enterprise_widgets.dart';
import 'package:logisticsmobile/widgets/app_card.dart';

class UserDetailArgs {
  const UserDetailArgs({
    required this.user,
    this.auditActivities = const [],
  });

  final WmsUser user;
  final List<AuditActivity> auditActivities;
}

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key, required this.args});

  final UserDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final user = args.user;
    final colors = WmsUiColors.of(context);
    final roleColor = UserRoleBadge.colorFor(user.role);
    final isActive = user.isActive;
    final loginActivities = _loginActivities(args.auditActivities, user);
    final statusChanges = _statusChanges(args.auditActivities, user);
    final loginCount = user.loginCount ?? loginActivities.length;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(user.displayName, style: WmsDesignTokens.cardTitle(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          AppCard(
            elevated: true,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: roleColor.withValues(alpha: 0.12),
                  child: Text(
                    user.initials,
                    style: WmsDesignTokens.sectionTitle(context).copyWith(color: roleColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName, style: WmsDesignTokens.sectionTitle(context)),
                      Text(user.email, style: WmsDesignTokens.supporting(context)),
                      Text('@${user.username}', style: WmsDesignTokens.supportingDense(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _DetailSection(
            title: 'Personal Information',
            children: [
              _InfoRow(label: 'Full Name', value: user.displayName),
              _InfoRow(label: 'Username', value: user.username),
              _InfoRow(label: 'Email', value: user.email),
              _InfoRow(label: 'Account Created', value: WmsFormatters.dateShort(user.createdAt)),
            ],
          ),
          _DetailSection(
            title: 'Role Information',
            children: [
              _InfoRow(label: 'Role', value: UserRoleBadge.labelFor(user)),
              _InfoRow(label: 'System Role', value: user.role),
            ],
          ),
          _DetailSection(
            title: 'Warehouse Assignment',
            children: [
              _InfoRow(
                label: 'Assigned Warehouse',
                value: user.assignedWarehouse ?? 'Not assigned',
              ),
            ],
          ),
          _DetailSection(
            title: 'Login History',
            children: [
              _InfoRow(
                label: 'Last Login',
                value: user.lastLoginAt != null
                    ? WmsFormatters.dateTimeShort(user.lastLoginAt)
                    : 'Never',
              ),
              _InfoRow(label: 'Login Count', value: loginCount > 0 ? '$loginCount' : '—'),
              if (loginActivities.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'No login activity records in the loaded audit feed.',
                    style: WmsDesignTokens.supporting(context),
                  ),
                )
              else
                for (final entry in loginActivities.take(5))
                  _ActivityTile(activity: entry),
            ],
          ),
          _DetailSection(
            title: 'Activity Logs',
            children: [
              if (args.auditActivities.isEmpty)
                Text(
                  'No activity logs for this user in the current session.',
                  style: WmsDesignTokens.supporting(context),
                )
              else
                for (final activity in args.auditActivities.take(8))
                  _ActivityTile(activity: activity),
            ],
          ),
          _DetailSection(
            title: 'Account Status',
            children: [
              _InfoRow(label: 'Status', value: user.status),
              _InfoRow(label: 'Archived', value: user.archived ? 'Yes' : 'No'),
              _InfoRow(
                label: 'Active in System',
                value: isActive ? 'Active' : 'Inactive',
              ),
              if (statusChanges.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Status Changes',
                  style: WmsDesignTokens.supportingDense(context).copyWith(fontWeight: FontWeight.w700),
                ),
                for (final change in statusChanges.take(5))
                  _ActivityTile(activity: change),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  static List<AuditActivity> _loginActivities(List<AuditActivity> all, WmsUser user) {
    final name = user.displayName.toLowerCase();
    final username = user.username.toLowerCase();
    return all.where((a) {
      final matchesUser = a.userName.toLowerCase() == name ||
          a.userName.toLowerCase() == username;
      if (!matchesUser) return false;
      final action = a.action.toLowerCase();
      return action.contains('login') || action.contains('sign in');
    }).toList();
  }

  static List<AuditActivity> _statusChanges(List<AuditActivity> all, WmsUser user) {
    final name = user.displayName.toLowerCase();
    final username = user.username.toLowerCase();
    return all.where((a) {
      final matchesUser = a.userName.toLowerCase() == name ||
          a.userName.toLowerCase() == username;
      if (!matchesUser) return false;
      final action = a.action.toLowerCase();
      return action.contains('status') ||
          action.contains('activate') ||
          action.contains('deactivate') ||
          action.contains('archive');
    }).toList();
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: WmsDesignTokens.sectionTitle(context)),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            elevated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: WmsDesignTokens.supporting(context)),
          ),
          Expanded(
            child: Text(
              value,
              style: WmsDesignTokens.body(context).copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final AuditActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.mutedSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(activity.action, style: WmsDesignTokens.cardTitle(context).copyWith(fontSize: 14)),
          Text(
            '${activity.module} · ${WmsFormatters.notificationTimestamp(activity.occurredAt)}',
            style: WmsDesignTokens.supportingDense(context),
          ),
          if (activity.details.isNotEmpty)
            Text(activity.details, style: WmsDesignTokens.supporting(context)),
        ],
      ),
    );
  }
}

void openUserDetail(
  BuildContext context,
  WmsUser user, {
  List<AuditActivity> auditActivities = const [],
}) {
  context.push(
    '/admin/users/${user.id}',
    extra: UserDetailArgs(user: user, auditActivities: auditActivities),
  );
}
