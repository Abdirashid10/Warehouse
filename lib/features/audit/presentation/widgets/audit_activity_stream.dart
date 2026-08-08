import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logisticsmobile/core/presentation/resource_state.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/audit/domain/entities/audit_activity.dart';
import 'package:logisticsmobile/features/audit/presentation/cubit/audit_cubit.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_premium_atoms.dart';
import 'package:logisticsmobile/features/audit/presentation/widgets/audit_premium_theme.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Reporting windows offered by the stream's segmented control.
enum AuditDateFilter { today, week, month, all }

/// Client-side date narrowing over the entries already loaded.
List<AuditActivity> filterAuditByDate(
  List<AuditActivity> activities,
  AuditDateFilter filter,
) {
  if (filter == AuditDateFilter.all) return activities;

  final now = DateTime.now();
  final DateTime start;
  switch (filter) {
    case AuditDateFilter.today:
      start = DateTime(now.year, now.month, now.day);
    case AuditDateFilter.week:
      start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
    case AuditDateFilter.month:
      start = DateTime(now.year, now.month, 1);
    case AuditDateFilter.all:
      return activities;
  }

  return activities.where((activity) {
    final occurredAt = activity.occurredAt;
    if (occurredAt == null) return false;
    return !occurredAt.isBefore(start);
  }).toList();
}

/// The premium audit activity stream: security header, floating search, dual
/// filters and a colour-coded timeline of every recorded action.
///
/// Owns only view state (date window, category snapshot); paging and querying
/// stay in [AuditCubit].
class AuditActivityStream extends StatefulWidget {
  const AuditActivityStream({
    super.key,
    required this.cubit,
    required this.searchController,
    this.padding = true,
    this.showHeader = true,
  });

  final AuditCubit cubit;
  final TextEditingController searchController;

  /// Applies full screen padding. `false` when hosted inside a tab that
  /// already insets its content.
  final bool padding;

  /// Hides the security header when the host screen provides its own chrome.
  final bool showHeader;

  @override
  State<AuditActivityStream> createState() => _AuditActivityStreamState();
}

class _AuditActivityStreamState extends State<AuditActivityStream> {
  static const _segments = [
    AuditSegment(value: AuditDateFilter.today, label: 'Today'),
    AuditSegment(value: AuditDateFilter.week, label: 'Week'),
    AuditSegment(value: AuditDateFilter.month, label: 'Month'),
    AuditSegment(value: AuditDateFilter.all, label: 'All'),
  ];

  /// Cap on category pills — beyond this the bar stops being scannable.
  static const _maxCategories = 8;

  AuditDateFilter _dateFilter = AuditDateFilter.all;

  /// Category counts captured from the last *unfiltered* load.
  ///
  /// While a module filter is active the server only returns that module, so
  /// recomputing counts then would zero every other pill. Holding the last
  /// complete snapshot keeps the badges meaningful.
  List<AuditCategory> _categorySnapshot = const [];

  bool get _hasActiveFilters =>
      _dateFilter != AuditDateFilter.all ||
      widget.searchController.text.isNotEmpty;

  void _resetFilters() {
    widget.searchController.clear();
    setState(() => _dateFilter = AuditDateFilter.all);
    widget.cubit.load();
  }

  List<AuditCategory> _buildCategories(AuditListState data) {
    if (data.moduleFilter != null && _categorySnapshot.isNotEmpty) {
      return _categorySnapshot;
    }

    final counts = <String, int>{};
    for (final activity in data.activities) {
      final module = activity.module.trim();
      if (module.isEmpty) continue;
      counts[module] = (counts[module] ?? 0) + 1;
    }

    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categories = <AuditCategory>[
      AuditCategory(label: 'All', count: data.activities.length),
      for (final entry in ranked.take(_maxCategories))
        AuditCategory(
          label: entry.key,
          value: entry.key,
          count: entry.value,
        ),
    ];

    if (data.moduleFilter == null) _categorySnapshot = categories;
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditCubit, ResourceState<AuditListState>>(
      builder: (context, state) {
        if (state.isLoading && state.data == null) {
          return const WmsListSkeleton();
        }

        final data = state.data;
        if (data == null) {
          return WmsErrorState(
            message: state.message ?? 'Failed to load audit logs',
            onRetry: widget.cubit.load,
          );
        }

        final visible = filterAuditByDate(data.activities, _dateFilter);
        final groups = _groupByDay(visible);
        final categories = _buildCategories(data);

        return ListView(
          padding: widget.padding
              ? const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                  AppSpacing.screenPadding,
                  AppSpacing.xxxl,
                )
              : const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.xxxl,
                ),
          children: [
            if (widget.showHeader) ...[
              AuditSecurityHeader(
                totalEntries: data.total,
                visibleEntries: visible.length,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AuditSearchBar(
              controller: widget.searchController,
              onChanged: (query) => widget.cubit.load(
                query: query.isEmpty ? null : query,
                module: data.moduleFilter,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AuditSegmentedControl<AuditDateFilter>(
              segments: _segments,
              selected: _dateFilter,
              onChanged: (value) => setState(() => _dateFilter = value),
            ),
            if (categories.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              AuditCategoryChips(
                categories: categories,
                selected: data.moduleFilter,
                onSelected: (module) => widget.cubit.load(
                  query: data.searchQuery.isEmpty ? null : data.searchQuery,
                  module: module,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (visible.isEmpty)
              AuditEmptyState(
                title: 'No audit entries',
                message: _hasActiveFilters || data.moduleFilter != null
                    ? 'No recorded activity matches the current window, '
                        'category or search terms.'
                    : 'Activity will appear here as soon as actions are '
                        'recorded against this workspace.',
                onReset: _hasActiveFilters || data.moduleFilter != null
                    ? _resetFilters
                    : null,
              )
            else
              ..._buildStream(groups),
            if (data.hasMore) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: data.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      )
                    : AuditGradientButton(
                        icon: Icons.expand_more_rounded,
                        label: 'Load older entries',
                        onPressed: widget.cubit.loadMore,
                      ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildStream(List<_DayGroup> groups) {
    final widgets = <Widget>[];

    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];
      widgets.add(
        AuditDayDivider(label: group.label, count: group.activities.length),
      );

      for (var i = 0; i < group.activities.length; i++) {
        final isLastOfAll =
            g == groups.length - 1 && i == group.activities.length - 1;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
            child: AuditTimelineTile(
              accent: AuditPalette.of(context).accentFor(
                AuditActionClassifier.classify(
                  group.activities[i].action,
                  group.activities[i].module,
                ).kind,
              ),
              isFirst: i == 0,
              isLast: isLastOfAll,
              card: AuditLogCard(activity: group.activities[i]),
            ),
          ),
        );
      }
    }

    return widgets;
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

// ─────────────────────────────────────────────────────────────────────────────
// Log card
// ─────────────────────────────────────────────────────────────────────────────

/// Formatting helpers for the stream's monospace elements.
abstract final class AuditStamp {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String date(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} ${_months[dt.month - 1]} ${dt.year}';

  /// Exact stamp, e.g. `12 Mar · 14:32`.
  static String exact(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')} ${_months[dt.month - 1]}'
        ' · $hour:$minute';
  }

  /// Short reference derived from the entry id, e.g. `#4F2A9C`.
  static String reference(String id) {
    final compact = id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (compact.isEmpty) return '#—';
    final tail = compact.length <= 6
        ? compact
        : compact.substring(compact.length - 6);
    return '#${tail.toUpperCase()}';
  }
}

/// A single audit entry rendered as an elevated, colour-coded log card.
class AuditLogCard extends StatelessWidget {
  const AuditLogCard({super.key, required this.activity});

  final AuditActivity activity;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final colors = palette.colors;
    final spec = AuditActionClassifier.classify(
      activity.action,
      activity.module,
    );
    final accent = palette.accentFor(spec.kind);
    final detail = AuditDetail.parse(activity.details);
    final occurredAt = activity.occurredAt;

    return AuditGlassCard(
      accentStrip: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuditIconWell(icon: spec.icon, color: accent),
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
                        activity.action,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WmsDesignTokens.cardTitle(context).copyWith(
                          color: colors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AuditTonePill(label: spec.label, color: accent),
                  ],
                ),
                const SizedBox(height: 5),
                _MetaLine(
                  userName: activity.userName,
                  module: activity.module,
                ),
                if (detail.route != null) ...[
                  const SizedBox(height: 8),
                  _RouteChip(route: detail.route!, accent: accent),
                ],
                if (detail.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.supporting(context).copyWith(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        occurredAt == null
                            ? 'No timestamp'
                            : '${WmsFormatters.relativeTime(occurredAt)}'
                                '  ·  ${AuditStamp.exact(occurredAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: palette.mono(
                          color: colors.textTertiary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AuditStamp.reference(activity.id),
                      maxLines: 1,
                      style: palette.mono(
                        color: colors.textTertiary.withValues(alpha: 0.85),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.userName, required this.module});

  final String userName;
  final String module;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final colors = palette.colors;
    final style = WmsDesignTokens.supportingDense(context).copyWith(
      color: colors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );

    return Row(
      children: [
        Icon(Icons.person_outline_rounded, size: 12, color: colors.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            userName.isEmpty ? 'System' : userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (module.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: colors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Flexible(
            child: Text(
              module,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Origin → destination route pulled out of the entry's detail text.
class _RouteChip extends StatelessWidget {
  const _RouteChip({required this.route, required this.accent});

  final AuditRoute route;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = AuditPalette.of(context);
    final colors = palette.colors;
    final style = WmsDesignTokens.supportingDense(context).copyWith(
      color: colors.textPrimary,
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: palette.insetFill,
        borderRadius: BorderRadius.circular(10),
        border: palette.glassBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              route.origin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Icon(Icons.arrow_forward_rounded, size: 13, color: accent),
          ),
          Flexible(
            child: Text(
              route.destination,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
