import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/audit/presentation/cubit/audit_cubit.dart';
import 'package:logisticsmobile/widgets/app_button.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

enum AuditDateFilter { all, today, week, month }

List<AuditActivity> filterAuditByDate(
  List<AuditActivity> activities,
  AuditDateFilter filter,
) {
  if (filter == AuditDateFilter.all) return activities;
  final now = DateTime.now();
  late DateTime start;
  switch (filter) {
    case AuditDateFilter.today:
      start = DateTime(now.year, now.month, now.day);
    case AuditDateFilter.week:
      start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    case AuditDateFilter.month:
      start = DateTime(now.year, now.month, 1);
    case AuditDateFilter.all:
      return activities;
  }
  return activities.where((a) {
    final dt = a.occurredAt;
    if (dt == null) return false;
    return !dt.isBefore(start);
  }).toList();
}

class AdminAuditPanel extends StatefulWidget {
  const AdminAuditPanel({
    super.key,
    required this.cubit,
    required this.searchController,
    this.padding = true,
  });

  final AuditCubit cubit;
  final TextEditingController searchController;
  final bool padding;

  @override
  State<AdminAuditPanel> createState() => _AdminAuditPanelState();
}

class _AdminAuditPanelState extends State<AdminAuditPanel> {
  AuditDateFilter _dateFilter = AuditDateFilter.all;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditCubit, ResourceState<AuditListState>>(
      builder: (context, state) {
        if (state.isLoading && state.data == null) {
          return const WmsListSkeleton();
        }
        if (state.isFailure && state.data == null) {
          return WmsErrorState(
            message: state.message ?? 'Failed to load audit logs',
            onRetry: widget.cubit.load,
          );
        }
        final data = state.data;
        if (data == null) return const SizedBox.shrink();

        final modules = data.activities.map((a) => a.module).toSet().toList()..sort();
        final filtered = filterAuditByDate(data.activities, _dateFilter);

        return ListView(
          padding: widget.padding
              ? const EdgeInsets.all(AppSpacing.screenPadding)
              : const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xxl),
          children: [
            WmsSearchField(
              hint: 'Search user, action, module…',
              controller: widget.searchController,
              onChanged: (q) => widget.cubit.load(
                query: q,
                module: data.moduleFilter,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<AuditDateFilter>(
              segments: const [
                ButtonSegment(value: AuditDateFilter.today, label: Text('Today')),
                ButtonSegment(value: AuditDateFilter.week, label: Text('Week')),
                ButtonSegment(value: AuditDateFilter.month, label: Text('Month')),
                ButtonSegment(value: AuditDateFilter.all, label: Text('All')),
              ],
              selected: {_dateFilter},
              onSelectionChanged: (set) => setState(() => _dateFilter = set.first),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (modules.isNotEmpty)
              WmsFilterChipBar(
                options: modules.take(10).toList(),
                selected: data.moduleFilter,
                onSelected: (m) => widget.cubit.load(
                  query: data.searchQuery.isEmpty ? null : data.searchQuery,
                  module: m,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            if (filtered.isEmpty)
              const WmsEmptyState(
                title: 'No audit entries',
                message: 'Adjust date filters or search to find activity.',
                icon: Icons.history,
              )
            else
              ...filtered.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _AuditLogCard(activity: a),
                ),
              ),
            if (data.hasMore) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: data.isLoadingMore
                    ? const CircularProgressIndicator()
                    : AppButton(
                        label: 'Load more',
                        fullWidth: false,
                        onPressed: widget.cubit.loadMore,
                      ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.activity});

  final AuditActivity activity;

  IconData _iconForAction(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('login')) return Icons.login;
    if (lower.contains('transfer')) return Icons.swap_horiz;
    if (lower.contains('inventory') || lower.contains('stock')) {
      return Icons.inventory_2_outlined;
    }
    if (lower.contains('order')) return Icons.shopping_cart_outlined;
    if (lower.contains('task')) return Icons.assignment_outlined;
    return Icons.history;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(_iconForAction(activity.action), color: AppColors.primary, size: WmsIconSizes.listLeading),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.userName} · ${activity.module}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (activity.details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(activity.details, style: Theme.of(context).textTheme.bodySmall),
                ],
                if (activity.occurredAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    WmsFormatters.relativeTime(activity.occurredAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
