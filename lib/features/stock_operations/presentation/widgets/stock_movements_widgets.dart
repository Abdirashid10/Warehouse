import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_dark_theme.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/features/stock_operations/presentation/cubit/movements_cubit.dart';

/// Stock movements audit trail — follows global app theme.
class StockMovementsAuditView extends StatelessWidget {
  const StockMovementsAuditView({
    super.key,
    required this.data,
    required this.searchController,
    required this.onSearch,
    required this.onTypeFilter,
    required this.onOpenDetail,
    this.embedded = false,
    this.selectedTypeFilter,
  });

  final MovementsViewState data;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onTypeFilter;
  final ValueChanged<StockMovement> onOpenDetail;
  final bool embedded;
  final String? selectedTypeFilter;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final stats = data.stats;
    final activeFilter = selectedTypeFilter ?? data.typeFilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded) ...[
          Text('Stock Movements', style: WmsDarkTheme.pageTitle(context)),
          const SizedBox(height: 4),
          Text(
            'Complete audit trail · ${stats.total} operations tracked',
            style: WmsDarkTheme.subtitle(context),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        SizedBox(
          height: MobileUi.horizontalKpiStripHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _MovementKpiChip(
                label: 'TOTAL',
                count: stats.total,
                icon: Icons.layers_outlined,
                color: colors.primary,
                selected: activeFilter == null,
                onTap: () => onTypeFilter(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              _MovementKpiChip(
                label: 'INBOUND',
                count: stats.inbound,
                icon: Icons.download_rounded,
                color: colors.success,
                selected: activeFilter == WmsMovementTypes.inbound,
                onTap: () => onTypeFilter(WmsMovementTypes.inbound),
              ),
              const SizedBox(width: AppSpacing.sm),
              _MovementKpiChip(
                label: 'OUTBOUND',
                count: stats.outbound,
                icon: Icons.upload_rounded,
                color: colors.outbound,
                selected: activeFilter == WmsMovementTypes.outbound,
                onTap: () => onTypeFilter(WmsMovementTypes.outbound),
              ),
              const SizedBox(width: AppSpacing.sm),
              _MovementKpiChip(
                label: 'TRANSFERS',
                count: stats.transfers,
                icon: Icons.swap_horiz_rounded,
                color: colors.primary,
                selected: activeFilter == WmsMovementTypes.transfer,
                onTap: () => onTypeFilter(WmsMovementTypes.transfer),
              ),
              const SizedBox(width: AppSpacing.sm),
              _MovementKpiChip(
                label: 'ADJUSTMENTS',
                count: stats.adjustments,
                icon: Icons.tune_rounded,
                color: colors.warning,
                selected: activeFilter == WmsMovementTypes.adjustment,
                onTap: () => onTypeFilter(WmsMovementTypes.adjustment),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: searchController,
          onChanged: onSearch,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search product, SKU, warehouse, staff…',
            prefixIcon: Icon(Icons.search, size: WmsIconSizes.search, color: colors.textTertiary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterPill(
                label: 'All',
                count: stats.total,
                selected: activeFilter == null,
                onTap: () => onTypeFilter(null),
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterPill(
                label: 'INBOUND',
                count: stats.inbound,
                selected: activeFilter == WmsMovementTypes.inbound,
                onTap: () => onTypeFilter(WmsMovementTypes.inbound),
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterPill(
                label: 'OUTBOUND',
                count: stats.outbound,
                selected: activeFilter == WmsMovementTypes.outbound,
                onTap: () => onTypeFilter(WmsMovementTypes.outbound),
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterPill(
                label: 'TRANSFER',
                count: stats.transfers,
                selected: activeFilter == WmsMovementTypes.transfer,
                onTap: () => onTypeFilter(WmsMovementTypes.transfer),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (data.filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: _MovementsEmptyState(),
          )
        else
          ...data.filtered.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: StockMovementAuditCard(
                movement: m,
                onTap: () => onOpenDetail(m),
              ),
            ),
          ),
      ],
    );
  }
}

class _MovementKpiChip extends StatelessWidget {
  const _MovementKpiChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return SizedBox(
      width: 118,
      child: Material(
        color: selected
            ? colors.primaryMuted.withValues(alpha: colors.isDark ? 0.6 : 0.35)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: WmsIconSizes.listLeading, color: color),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.metricValue(context).copyWith(
                    fontSize: 20,
                    height: 1.1,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDarkTheme.sectionLabel(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Material(
      color: selected ? colors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: selected ? null : Border.all(color: colors.border),
          ),
          child: Text(
            '$label $count',
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: selected ? colors.onPrimary : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class StockMovementAuditCard extends StatelessWidget {
  const StockMovementAuditCard({
    super.key,
    required this.movement,
    required this.onTap,
  });

  final StockMovement movement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final route = MovementUi.routeLabel(movement);
    final qty = MovementUi.signedQuantity(context, movement);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  MovementTypeBadge(type: movement.type),
                  const Spacer(),
                  _QtyBadge(label: qty.label, color: qty.color),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                movement.productName,
                style: WmsDesignTokens.body(context).copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(movement.sku, style: WmsDarkTheme.subtitle(context)),
              const SizedBox(height: AppSpacing.sm),
              _MetaRow(icon: Icons.route_outlined, label: 'Route', value: route),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _MetaRow(
                      icon: Icons.person_outline,
                      label: 'By',
                      value: movement.performedBy,
                    ),
                  ),
                  Text(
                    MovementUi.shortDate(movement.timestamp),
                    style: WmsDarkTheme.subtitle(context),
                  ),
                ],
              ),
              if (movement.notes != null && movement.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _MetaRow(
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: movement.notes!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MovementTypeBadge extends StatelessWidget {
  const MovementTypeBadge({super.key, required this.type});

  final String type;

  (Color bg, Color fg) _colors(WmsUiColors colors) {
    final t = type.toUpperCase();
    if (t.contains('IN')) {
      return colors.isDark
          ? (const Color(0xFF14532D), colors.success)
          : (const Color(0xFFDCFCE7), colors.success);
    }
    if (t.contains('OUT')) {
      return colors.isDark
          ? (const Color(0xFF431407), colors.outbound)
          : (const Color(0xFFFFEDD5), colors.outbound);
    }
    if (t.contains('TRANSFER')) {
      return colors.isDark
          ? (const Color(0xFF0C4A6E), colors.primary)
          : (const Color(0xFFDBEAFE), colors.primary);
    }
    if (t.contains('ADJUST')) {
      return colors.isDark
          ? (const Color(0xFF422006), colors.warning)
          : (const Color(0xFFFFEDD5), colors.warning);
    }
    if (t.contains('RETURN')) {
      return colors.isDark
          ? (const Color(0xFF134E4A), const Color(0xFF2DD4BF))
          : (const Color(0xFFCCFBF1), const Color(0xFF0D9488));
    }
    return (colors.surfaceElevated, colors.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final (bg, fg) = _colors(colors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        type.toUpperCase(),
        style: WmsDesignTokens.supportingDense(context).copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _QtyBadge extends StatelessWidget {
  const _QtyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: WmsDesignTokens.supportingDense(context).copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: WmsIconSizes.status, color: colors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: WmsDarkTheme.subtitle(context),
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(color: colors.textTertiary),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MovementsEmptyState extends StatelessWidget {
  const _MovementsEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      children: [
        Icon(Icons.swap_horiz, size: WmsIconSizes.emptyState, color: colors.textTertiary),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'No movements match your filters',
          style: WmsDesignTokens.body(context).copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

abstract final class MovementUi {
  static String routeLabel(StockMovement m) {
    final type = m.type.toUpperCase();
    final from = m.fromLocation;
    final to = m.toLocation;
    if (type.contains('TRANSFER') && from != null && to != null) {
      return '@ $from → @ $to';
    }
    if (from != null && from.isNotEmpty) return '@ $from';
    if (to != null && to.isNotEmpty) return '@ $to';
    return '—';
  }

  static ({String label, Color color}) signedQuantity(
    BuildContext context,
    StockMovement m,
  ) {
    final colors = WmsUiColors.of(context);
    final type = m.type.toUpperCase();
    final q = WmsFormatters.quantity(m.quantity);
    if (type.contains('IN') || type.contains('RETURN')) {
      return (label: '+$q', color: colors.success);
    }
    if (type.contains('OUT')) {
      return (label: '-$q', color: colors.error);
    }
    if (type.contains('TRANSFER')) {
      return (label: '↔ $q', color: colors.primary);
    }
    return (label: q, color: colors.warning);
  }

  static String shortDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

void showStockMovementDetailSheet(BuildContext context, StockMovement movement) {
  final colors = WmsUiColors.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MovementTypeBadge(type: movement.type),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              movement.productName,
              style: WmsDarkTheme.pageTitle(context).copyWith(fontSize: 20),
            ),
            Text(movement.sku, style: WmsDarkTheme.subtitle(context)),
            const SizedBox(height: AppSpacing.md),
            _DetailRow('Route', MovementUi.routeLabel(movement)),
            _DetailRow(
              'Quantity',
              MovementUi.signedQuantity(context, movement).label,
            ),
            _DetailRow('Performed by', movement.performedBy),
            _DetailRow(
              'Date',
              movement.timestamp != null
                  ? WmsFormatters.notificationTimestamp(movement.timestamp)
                  : '—',
            ),
            _DetailRow('Notes', movement.notes ?? '—'),
          ],
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: WmsDarkTheme.sectionLabel(context)),
          ),
          Expanded(
            child: Text(
              value,
              style: WmsDesignTokens.body(context).copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// @deprecated Use [MovementTypeBadge].
typedef MovementTypeBadgeDark = MovementTypeBadge;
