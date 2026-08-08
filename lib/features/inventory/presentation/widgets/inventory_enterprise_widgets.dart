import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/presentation/cubit/inventory_cubit.dart'
    show InventorySortField, InventoryViewState;
import 'package:logisticsmobile/features/inventory/presentation/utils/inventory_metrics.dart';
import 'package:logisticsmobile/features/stock_operations/domain/entities/stock_movement.dart';
import 'package:logisticsmobile/routes/route_names.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/wms/enterprise/wms_dashboard_section.dart';
import 'package:logisticsmobile/widgets/wms/wms_badges.dart';

extension InventorySortFieldUi on InventorySortField {
  String get label => switch (this) {
        InventorySortField.name => 'Name',
        InventorySortField.quantity => 'Quantity',
        InventorySortField.stockLevel => 'Stock Level',
        InventorySortField.warehouse => 'Warehouse',
        InventorySortField.lastUpdated => 'Last Updated',
      };

  IconData get icon => switch (this) {
        InventorySortField.name => Icons.sort_by_alpha_rounded,
        InventorySortField.quantity => Icons.numbers_rounded,
        InventorySortField.stockLevel => Icons.signal_cellular_alt_rounded,
        InventorySortField.warehouse => Icons.warehouse_outlined,
        InventorySortField.lastUpdated => Icons.update_rounded,
      };
}

/// Enterprise inventory helpers — status colors, search, and layout tokens.
abstract final class InventoryUi {
  static const sectionGap = WmsDesignTokens.sectionGap;
  static const expiredPurple = Color(0xFF7C3AED);
  static const expiredPurpleLight = Color(0xFFEDE9FE);

  static String get expiredLabel => WmsStockStatuses.expired;

  static bool isExpired(InventoryItem item) {
    final expiry = item.expiryDate;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  static int expiredCount(Iterable<InventoryItem> items) =>
      items.where(isExpired).length;

  static String displayStatus(InventoryItem item) {
    if (isExpired(item)) return expiredLabel;
    return item.stockStatus;
  }

  /// Ink for a stock-status indicator.
  ///
  /// Takes [colors] rather than reading a static palette: the same status has
  /// to resolve to a different swatch per brightness, and a `static` helper
  /// has no context of its own to read one from.
  static Color indicatorColor(String status, [WmsUiColors? colors]) {
    final palette = colors ?? WmsUiColors.lightPalette();
    switch (status) {
      case WmsStockStatuses.inStock:
        return palette.success;
      case WmsStockStatuses.lowStock:
        return palette.warning;
      case WmsStockStatuses.outOfStock:
        return palette.error;
      case WmsStockStatuses.expired:
        return palette.expired;
      default:
        return palette.textSecondary;
    }
  }

  /// Well behind a stock-status indicator, matched to [indicatorColor].
  static Color indicatorBackground(String status, [WmsUiColors? colors]) {
    final palette = colors ?? WmsUiColors.lightPalette();
    switch (status) {
      case WmsStockStatuses.inStock:
        return palette.successMuted;
      case WmsStockStatuses.lowStock:
        return palette.warningMuted;
      case WmsStockStatuses.outOfStock:
        return palette.errorMuted;
      case WmsStockStatuses.expired:
        return palette.expiredMuted;
      default:
        return palette.surfaceElevated;
    }
  }

  static DateTime? lastUpdatedFor(
    InventoryItem item,
    List<StockMovement> movements,
  ) {
    DateTime? latest;
    for (final m in movements) {
      if (m.sku != item.sku && m.productName != item.productName) continue;
      final ts = m.timestamp;
      if (ts == null) continue;
      if (latest == null || ts.isAfter(latest)) latest = ts;
    }
    return latest;
  }

  static String stockOpsRoute(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/admin')) return RoutePaths.adminStockOperations;
    if (path.startsWith('/supervisor')) {
      return RoutePaths.supervisorStockOperations;
    }
    return RoutePaths.staffStockOperations;
  }

  static void navigateToStockOperation(BuildContext context, {int tab = 0}) {
    context.push(stockOpsRoute(context), extra: tab.clamp(0, 5));
  }

  static void showRecordStockSheet(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final wms = context.wms;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) {
        final options = [
          (
            label: 'Receive Stock',
            icon: Icons.download_rounded,
            color: colors.success,
            tab: 0,
          ),
          (
            label: 'Dispatch Stock',
            icon: Icons.upload_rounded,
            color: colors.outbound,
            tab: 1,
          ),
          (
            label: 'Transfer Stock',
            icon: Icons.swap_horiz_rounded,
            color: colors.info,
            tab: 2,
          ),
          (
            label: 'Adjust Stock',
            icon: Icons.tune_rounded,
            color: colors.accent,
            tab: 0,
          ),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Record Stock',
                  style: WmsDesignTokens.sectionTitle(sheetContext),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Choose a stock operation',
                  style: WmsDesignTokens.supporting(sheetContext).copyWith(
                    color: wms.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final option in options) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: option.color.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(option.icon, color: option.color, size: WmsIconSizes.dashboardCard),
                    ),
                    title: Text(
                      option.label,
                      style: WmsDesignTokens.body(sheetContext).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: wms.textTertiary,
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      navigateToStockOperation(context, tab: option.tab);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String exportCsv(
    InventoryViewState data, {
    Iterable<InventoryItem>? items,
  }) {
    final rows = items ?? data.sortedFiltered;
    final buffer = StringBuffer(
      'SKU,Product,Warehouse,Quantity,Min Quantity,Status,Stock Value,Category\n',
    );
    for (final item in rows) {
      final status = displayStatus(item);
      final category = data.categoryFor(item);
      final min = item.minThreshold?.toString() ?? '';
      final value = data.stockValueFor(item);
      buffer.writeln(
        '"${item.sku}","${item.productName}","${item.warehouseName}",'
        '${item.quantity},$min,"$status",${value.toStringAsFixed(2)},"$category"',
      );
    }
    return buffer.toString();
  }

  static Future<void> exportToClipboard(
    BuildContext context,
    InventoryViewState data, {
    Iterable<InventoryItem>? items,
  }) async {
    final csv = exportCsv(data, items: items);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    final count = items?.length ?? data.sortedFiltered.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported $count inventory lines to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Mobile-first inventory page header — title, subtitle, full-width Record Stock.
class InventoryTrackingHeader extends StatelessWidget {
  const InventoryTrackingHeader({super.key});

  static const double _stackedBreakpoint = 430;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final colors = WmsUiColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xs,
      ),
      child: width < _stackedBreakpoint
          ? _StackedHeader(colors: colors)
          : _WideHeader(colors: colors),
    );
  }
}

class _StackedHeader extends StatelessWidget {
  const _StackedHeader({required this.colors});

  final WmsUiColors colors;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Inventory Tracking',
          maxLines: 2,
          softWrap: true,
          style: WmsDesignTokens.pageTitle(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Organization-wide stock levels',
          style: WmsDesignTokens.pageSubtitle(context).copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _RecordStockButton(fullWidth: true),
      ],
    );
  }
}

class _WideHeader extends StatelessWidget {
  const _WideHeader({required this.colors});

  final WmsUiColors colors;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Column(
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
                    'Inventory Tracking',
                    maxLines: 2,
                    softWrap: true,
                    style: WmsDesignTokens.pageTitle(context),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Organization-wide stock levels',
                    style: WmsDesignTokens.pageSubtitle(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _RecordStockButton(fullWidth: false),
          ],
        ),
      ],
    );
  }
}

class _RecordStockButton extends StatelessWidget {
  const _RecordStockButton({required this.fullWidth});

  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final button = FilledButton.icon(
      onPressed: () => InventoryUi.showRecordStockSheet(context),
      icon: const Icon(Icons.add, size: WmsIconSizes.actionButton),
      label: const Text('Record Stock'),
      style: FilledButton.styleFrom(
        minimumSize: Size(fullWidth ? double.infinity : 0, 48),
        fixedSize: fullWidth ? const Size.fromHeight(48) : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: WmsDesignTokens.buttonLabel(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, height: 48, child: button);
    }

    return SizedBox(height: 48, child: button);
  }
}

class InventoryCriticalAlertsSection extends StatelessWidget {
  const InventoryCriticalAlertsSection({
    super.key,
    required this.data,
    this.onItemTap,
  });

  final InventoryViewState data;
  final void Function(InventoryItem item)? onItemTap;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final low = data.items
        .where((i) => i.stockStatus == WmsStockStatuses.lowStock)
        .toList();
    final out = data.items
        .where((i) => i.stockStatus == WmsStockStatuses.outOfStock)
        .toList();
    final expired = data.items.where(InventoryUi.isExpired).toList();

    if (low.isEmpty && out.isEmpty && expired.isEmpty) {
      return const SizedBox.shrink();
    }

    return WmsDashboardSection(
      title: 'Low Stock & Critical Alerts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (low.isNotEmpty)
            _CriticalAlertGroup(
              title: 'Low Stock Products',
              color: colors.warning,
              icon: Icons.trending_down_rounded,
              items: low,
              onItemTap: onItemTap,
            ),
          if (low.isNotEmpty && (out.isNotEmpty || expired.isNotEmpty))
            const SizedBox(height: AppSpacing.sm),
          if (out.isNotEmpty)
            _CriticalAlertGroup(
              title: 'Out Of Stock Products',
              color: colors.error,
              icon: Icons.remove_shopping_cart_outlined,
              items: out,
              onItemTap: onItemTap,
            ),
          if (out.isNotEmpty && expired.isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          if (expired.isNotEmpty)
            _CriticalAlertGroup(
              title: 'Expired Products',
              color: InventoryUi.expiredPurple,
              icon: Icons.event_busy_outlined,
              items: expired,
              onItemTap: onItemTap,
            ),
        ],
      ),
    );
  }
}

class _CriticalAlertGroup extends StatelessWidget {
  const _CriticalAlertGroup({
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
    this.onItemTap,
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<InventoryItem> items;
  final void Function(InventoryItem item)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: WmsIconSizes.kpi, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$title (${items.length})',
                  style: WmsDesignTokens.cardTitle(context).copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < items.length && i < 6; i++) ...[
            if (i > 0) Divider(height: AppSpacing.md, color: context.wms.divider),
            InkWell(
              onTap: onItemTap != null ? () => onItemTap!(items[i]) : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.body(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            'SKU ${items[i].sku} · ${items[i].warehouseName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WmsDesignTokens.supportingDense(context),
                          ),
                        ],
                      ),
                    ),
                    WmsStockStatusBadge(
                      status: InventoryUi.displayStatus(items[i]),
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact operational shortcuts in the command-center header.
class InventoryHeaderQuickActions extends StatelessWidget {
  const InventoryHeaderQuickActions({super.key, required this.stockRoute});

  final String stockRoute;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderIconAction(
          icon: Icons.download_rounded,
          tooltip: 'Receive stock',
          color: colors.success,
          onTap: () => context.push(stockRoute),
        ),
        _HeaderIconAction(
          icon: Icons.upload_rounded,
          tooltip: 'Dispatch stock',
          color: colors.outbound,
          onTap: () => context.push(stockRoute),
        ),
        _HeaderIconAction(
          icon: Icons.swap_horiz_rounded,
          tooltip: 'Transfer stock',
          color: colors.info,
          onTap: () => context.push(stockRoute),
        ),
      ],
    );
  }
}

class _HeaderIconAction extends StatelessWidget {
  const _HeaderIconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: WmsIconSizes.kpi, color: color),
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        minimumSize: const Size(36, 36),
      ),
    );
  }
}

/// SAP-style segmented stock health visualization.
class InventoryStockHealthBar extends StatelessWidget {
  const InventoryStockHealthBar({
    super.key,
    required this.summary,
    required this.expired,
  });

  final InventorySummary summary;
  final int expired;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final wms = context.wms;
    final total = summary.inStock +
        summary.lowStock +
        summary.outOfStock +
        expired;
    if (total == 0) return const SizedBox.shrink();

    double flex(int count) => count == 0 ? 0 : count / total;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Stock Health',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                '$total SKU lines',
                style: WmsDesignTokens.supportingDense(context).copyWith(
                      color: wms.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (summary.inStock > 0)
                    Expanded(
                      flex: (flex(summary.inStock) * 1000).round().clamp(1, 1000),
                      child: ColoredBox(color: colors.success),
                    ),
                  if (summary.lowStock > 0)
                    Expanded(
                      flex: (flex(summary.lowStock) * 1000).round().clamp(1, 1000),
                      child: ColoredBox(color: colors.warning),
                    ),
                  if (summary.outOfStock > 0)
                    Expanded(
                      flex: (flex(summary.outOfStock) * 1000).round().clamp(1, 1000),
                      child: ColoredBox(color: colors.error),
                    ),
                  if (expired > 0)
                    Expanded(
                      flex: (flex(expired) * 1000).round().clamp(1, 1000),
                      child: ColoredBox(color: InventoryUi.expiredPurple),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _HealthLegend(
                color: colors.success,
                label: 'In Stock',
                count: summary.inStock,
              ),
              _HealthLegend(
                color: colors.warning,
                label: 'Low',
                count: summary.lowStock,
              ),
              _HealthLegend(
                color: colors.error,
                label: 'Out',
                count: summary.outOfStock,
              ),
              _HealthLegend(
                color: InventoryUi.expiredPurple,
                label: 'Expired',
                count: expired,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthLegend extends StatelessWidget {
  const _HealthLegend({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: color),
        const SizedBox(width: 4),
        Text(
          '$label $count',
          style: WmsDesignTokens.supportingDense(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// Warehouse-level inventory card with stock health breakdown.
class InventoryWarehouseOverviewCard extends StatelessWidget {
  const InventoryWarehouseOverviewCard({
    super.key,
    required this.name,
    required this.items,
  });

  final String name;
  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final wms = context.wms;
    final totalUnits = items.fold<num>(0, (sum, item) => sum + item.quantity);
    final breakdown = InventoryMetrics.breakdownFor(items);
    final total = breakdown.inStock +
        breakdown.low +
        breakdown.out +
        breakdown.expired;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: wms.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.warehouse_outlined,
                  size: WmsIconSizes.status,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '${items.length} SKUs · ${WmsFormatters.quantity(totalUnits)} units',
                      style: WmsDesignTokens.supportingDense(context).copyWith(
                            color: wms.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    if (breakdown.inStock > 0)
                      Expanded(
                        flex: breakdown.inStock,
                        child: ColoredBox(color: colors.success),
                      ),
                    if (breakdown.low > 0)
                      Expanded(
                        flex: breakdown.low,
                        child: ColoredBox(color: colors.warning),
                      ),
                    if (breakdown.out > 0)
                      Expanded(
                        flex: breakdown.out,
                        child: ColoredBox(color: colors.error),
                      ),
                    if (breakdown.expired > 0)
                      Expanded(
                        flex: breakdown.expired,
                        child: ColoredBox(color: InventoryUi.expiredPurple),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 2,
              children: [
                _WarehouseStatPill(
                  label: 'In',
                  count: breakdown.inStock,
                  color: colors.success,
                ),
                _WarehouseStatPill(
                  label: 'Low',
                  count: breakdown.low,
                  color: colors.warning,
                ),
                _WarehouseStatPill(
                  label: 'Out',
                  count: breakdown.out,
                  color: colors.error,
                ),
                if (breakdown.expired > 0)
                  _WarehouseStatPill(
                    label: 'Exp',
                    count: breakdown.expired,
                    color: InventoryUi.expiredPurple,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WarehouseStatPill extends StatelessWidget {
  const _WarehouseStatPill({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 6, color: color),
        const SizedBox(width: 3),
        Text(
          '$label $count',
          style: WmsDesignTokens.supportingDense(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class InventoryQuickActionsBar extends StatelessWidget {
  const InventoryQuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final stockRoute = InventoryUi.stockOpsRoute(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionChip(
            label: 'Receive',
            icon: Icons.download_rounded,
            color: colors.success,
            onTap: () => context.push(stockRoute),
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionChip(
            label: 'Dispatch',
            icon: Icons.upload_rounded,
            color: const Color(0xFFC2410C),
            onTap: () => context.push(stockRoute),
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionChip(
            label: 'Transfer',
            icon: Icons.swap_horiz_rounded,
            color: colors.info,
            onTap: () => context.push(stockRoute),
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionChip(
            label: 'View History',
            icon: Icons.history_rounded,
            color: colors.primary,
            onTap: () => context.push(stockRoute),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: WmsIconSizes.status, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryStatusChipBar extends StatelessWidget {
  const InventoryStatusChipBar({
    super.key,
    required this.data,
    required this.onStockFilter,
  });

  final InventoryViewState data;
  final ValueChanged<String?> onStockFilter;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final expired = InventoryUi.expiredCount(data.items);
    final selected = data.stockFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusChip(
            label: 'All',
            count: data.summary.inStock +
                data.summary.lowStock +
                data.summary.outOfStock,
            color: colors.primary,
            selected: selected == null,
            onTap: () => onStockFilter(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          _StatusChip(
            label: 'In Stock',
            count: data.summary.inStock,
            color: colors.success,
            selected: selected == 'in',
            onTap: () => onStockFilter(selected == 'in' ? null : 'in'),
          ),
          const SizedBox(width: AppSpacing.xs),
          _StatusChip(
            label: 'Low Stock',
            count: data.summary.lowStock,
            color: colors.warning,
            selected: selected == 'low',
            onTap: () => onStockFilter(selected == 'low' ? null : 'low'),
          ),
          const SizedBox(width: AppSpacing.xs),
          _StatusChip(
            label: 'Out of Stock',
            count: data.summary.outOfStock,
            color: colors.error,
            selected: selected == 'out',
            onTap: () => onStockFilter(selected == 'out' ? null : 'out'),
          ),
          const SizedBox(width: AppSpacing.xs),
          _StatusChip(
            label: 'Expired',
            count: expired,
            color: InventoryUi.expiredPurple,
            selected: selected == 'expired',
            onTap: () => onStockFilter(selected == 'expired' ? null : 'expired'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '$count',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: Icon(Icons.circle, size: 8, color: color),
      selectedColor: color.withValues(alpha: 0.14),
      side: BorderSide(
        color: selected ? color : color.withValues(alpha: 0.25),
      ),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class InventoryBulkActionsBar extends StatelessWidget {
  const InventoryBulkActionsBar({
    super.key,
    required this.data,
    required this.stockRoute,
    this.selectedItems = const [],
  });

  final InventoryViewState data;
  final String stockRoute;
  final List<InventoryItem> selectedItems;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final exportItems =
        selectedItems.isNotEmpty ? selectedItems : data.sortedFiltered;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                '${selectedItems.length} selected',
                style: WmsDesignTokens.supportingDense(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _BulkActionChip(
                  label: 'Transfer',
                  icon: Icons.swap_horiz_rounded,
                  color: colors.info,
                  onTap: () => context.push(stockRoute),
                ),
                const SizedBox(width: AppSpacing.xs),
                _BulkActionChip(
                  label: 'Adjust',
                  icon: Icons.tune_rounded,
                  color: colors.accent,
                  onTap: () => context.push(stockRoute),
                ),
                const SizedBox(width: AppSpacing.xs),
                _BulkActionChip(
                  label: 'Export',
                  icon: Icons.ios_share_rounded,
                  color: colors.primary,
                  onTap: () => InventoryUi.exportToClipboard(
                    context,
                    data,
                    items: exportItems,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkActionChip extends StatelessWidget {
  const _BulkActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: WmsIconSizes.kpi, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: WmsDesignTokens.body(context).copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryWarehouseChipBar extends StatelessWidget {
  const InventoryWarehouseChipBar({
    super.key,
    required this.warehouses,
    required this.selectedId,
    required this.onSelected,
  });

  final List<WarehouseOption> warehouses;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _WarehouseChip(
            label: 'All',
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          for (final w in warehouses) ...[
            const SizedBox(width: AppSpacing.xs),
            _WarehouseChip(
              label: w.name,
              selected: selectedId == w.id,
              onTap: () => onSelected(w.id),
              icon: Icons.warehouse_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _WarehouseChip extends StatelessWidget {
  const _WarehouseChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final wms = context.wms;

    return Material(
      color: selected ? wms.primaryLight : wms.surfaceVariant,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: WmsIconSizes.status, color: selected ? primary : wms.textSecondary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.body(context).copyWith(
                      color: selected ? primary : wms.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryTabBar extends StatelessWidget implements PreferredSizeWidget {
  const InventoryTabBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final wms = context.wms;

    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: wms.border.withValues(alpha: 0.5),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primary, width: 2.5),
        borderRadius: BorderRadius.circular(2),
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
      unselectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: wms.textSecondary,
          ),
      tabs: const [
        Tab(text: 'Products'),
        Tab(text: 'Summary'),
        Tab(text: 'Warehouses'),
        Tab(text: 'Alerts'),
      ],
    );
  }
}

/// Compact stock health overview for Summary tab.
class InventorySummaryPanel extends StatelessWidget {
  const InventorySummaryPanel({super.key, required this.data});

  final InventoryViewState data;

  @override
  Widget build(BuildContext context) {
    final colors = WmsUiColors.of(context);
    final expired = InventoryUi.expiredCount(data.items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InventoryStockHealthBar(
          summary: data.summary,
          expired: expired,
        ),
        const SizedBox(height: InventoryUi.sectionGap),
        WmsDashboardSection(
          title: 'Inventory Summary',
          child: AppCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _SummaryMetricRow('Total Products', '${InventoryMetrics.uniqueProductCount(data.items)}'),
                _SummaryMetricRow(
                  'Total Units',
                  WmsFormatters.quantity(data.summary.totalUnits),
                ),
                _SummaryMetricRow(
                  'Total Warehouses',
                  '${data.uniqueWarehouseCount}',
                ),
                _SummaryMetricRow(
                  'Stock Value',
                  WmsFormatters.currency(data.stockValueEstimate),
                ),
                const Divider(height: AppSpacing.lg),
                _SummaryMetricRow(
                  'In Stock',
                  '${data.summary.inStock}',
                  color: colors.success,
                ),
                _SummaryMetricRow(
                  'Low Stock',
                  '${data.summary.lowStock}',
                  color: colors.warning,
                ),
                _SummaryMetricRow(
                  'Out of Stock',
                  '${data.summary.outOfStock}',
                  color: colors.error,
                ),
                _SummaryMetricRow(
                  WmsStockStatuses.expired,
                  '$expired',
                  color: InventoryUi.expiredPurple,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryMetricRow extends StatelessWidget {
  const _SummaryMetricRow(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (color != null) ...[
            Icon(Icons.circle, size: 6, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
