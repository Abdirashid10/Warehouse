import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_theme_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';
import 'package:logisticsmobile/core/utils/mobile_ui.dart';
import 'package:logisticsmobile/core/utils/wms_formatters.dart';
import 'package:logisticsmobile/features/inventory/domain/entities/inventory_item.dart';
import 'package:logisticsmobile/features/inventory/presentation/cubit/inventory_cubit.dart'
    show InventorySortField, InventoryViewState;
import 'package:logisticsmobile/features/inventory/presentation/utils/inventory_metrics.dart';
import 'package:logisticsmobile/features/inventory/presentation/widgets/inventory_analytics_widgets.dart';
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

  static Color indicatorColor(String status) {
    switch (status) {
      case WmsStockStatuses.inStock:
        return AppColors.success;
      case WmsStockStatuses.lowStock:
        return AppColors.warning;
      case WmsStockStatuses.outOfStock:
        return AppColors.error;
      case WmsStockStatuses.expired:
        return expiredPurple;
      default:
        return AppThemeColors.lightTextSecondary;
    }
  }

  static Color indicatorBackground(String status) {
    switch (status) {
      case WmsStockStatuses.inStock:
        return AppColors.successLight;
      case WmsStockStatuses.lowStock:
        return AppColors.warningLight;
      case WmsStockStatuses.outOfStock:
        return AppColors.errorLight;
      case WmsStockStatuses.expired:
        return expiredPurpleLight;
      default:
        return AppColors.surfaceVariant;
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
            color: AppColors.success,
            tab: 0,
          ),
          (
            label: 'Dispatch Stock',
            icon: Icons.upload_rounded,
            color: AppColors.outbound,
            tab: 1,
          ),
          (
            label: 'Transfer Stock',
            icon: Icons.swap_horiz_rounded,
            color: AppColors.info,
            tab: 2,
          ),
          (
            label: 'Adjust Stock',
            icon: Icons.tune_rounded,
            color: AppColors.accent,
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

class InventorySummarySection extends StatelessWidget {
  const InventorySummarySection({super.key, required this.data});

  final InventoryViewState data;

  @override
  Widget build(BuildContext context) {
    final expired = data.expiredCount;
    final kpis = [
      (
        label: 'Total Units',
        value: WmsFormatters.quantity(data.summary.totalUnits),
        icon: Icons.inventory_2_outlined,
        color: AppColors.info,
      ),
      (
        label: 'In Stock',
        value: '${data.summary.inStock}',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      (
        label: 'Low Stock',
        value: '${data.summary.lowStock}',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      ),
      (
        label: 'Out Of Stock',
        value: '${data.summary.outOfStock}',
        icon: Icons.remove_shopping_cart_outlined,
        color: AppColors.error,
      ),
      (
        label: 'Expired',
        value: '$expired',
        icon: Icons.event_busy_outlined,
        color: InventoryUi.expiredPurple,
      ),
      (
        label: 'Expiring Soon',
        value: '${data.expiringSoonCount}',
        icon: Icons.schedule_outlined,
        color: AppColors.warning,
      ),
      (
        label: 'Expiring 30 Days',
        value: '${data.expiring30DaysCount}',
        icon: Icons.date_range_outlined,
        color: AppColors.info,
      ),
      (
        label: 'Safe',
        value: '${data.safeCount}',
        icon: Icons.verified_outlined,
        color: AppColors.success,
      ),
    ];

    return WmsDashboardSection(
      title: 'Inventory Summary',
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: MobileUi.phoneKpiGridDelegate(),
        children: [
          for (final kpi in kpis)
            AppCard(
              elevated: true,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(kpi.icon, size: WmsIconSizes.kpi, color: kpi.color),
                  const SizedBox(height: AppSpacing.sm),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      kpi.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WmsDesignTokens.kpiValue(
                        context,
                        width: MediaQuery.sizeOf(context).width,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    kpi.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.kpiLabel(context),
                  ),
                ],
              ),
            ),
        ],
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
    final button = FilledButton.icon(
      onPressed: () => InventoryUi.showRecordStockSheet(context),
      icon: const Icon(Icons.add, size: WmsIconSizes.actionButton),
      label: const Text('Record Stock'),
      style: FilledButton.styleFrom(
        minimumSize: Size(fullWidth ? double.infinity : 0, 48),
        fixedSize: fullWidth ? const Size.fromHeight(48) : null,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        backgroundColor: AppColors.primary,
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

class InventoryOperationsSection extends StatelessWidget {
  const InventoryOperationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        label: 'Receive',
        icon: Icons.download_rounded,
        color: AppColors.success,
        tab: 0,
      ),
      (
        label: 'Dispatch',
        icon: Icons.upload_rounded,
        color: AppColors.outbound,
        tab: 1,
      ),
      (
        label: 'Transfer',
        icon: Icons.swap_horiz_rounded,
        color: AppColors.info,
        tab: 2,
      ),
      (
        label: 'Adjust Stock',
        icon: Icons.tune_rounded,
        color: AppColors.accent,
        tab: 0,
      ),
    ];

    return WmsDashboardSection(
      title: 'Inventory Actions',
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: MobileUi.phoneKpiGridDelegate(),
        children: [
          for (final action in actions)
            AppCard(
              elevated: true,
              onTap: () =>
                  InventoryUi.navigateToStockOperation(context, tab: action.tab),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(action.icon, size: WmsIconSizes.dashboardCard, color: action.color),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    action.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WmsDesignTokens.body(context).copyWith(
                      color: action.color,
                      fontWeight: FontWeight.w700,
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
              color: AppColors.warning,
              icon: Icons.trending_down_rounded,
              items: low,
              onItemTap: onItemTap,
            ),
          if (low.isNotEmpty && (out.isNotEmpty || expired.isNotEmpty))
            const SizedBox(height: AppSpacing.sm),
          if (out.isNotEmpty)
            _CriticalAlertGroup(
              title: 'Out Of Stock Products',
              color: AppColors.error,
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

/// @deprecated Use [InventorySummarySection] + [InventoryAnalyticsSection].
class InventoryExecutiveHeader extends StatelessWidget {
  const InventoryExecutiveHeader({super.key, required this.data});

  final InventoryViewState data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InventorySummarySection(data: data),
        const SizedBox(height: InventoryUi.sectionGap),
        InventoryAnalyticsSection(data: data),
      ],
    );
  }
}

/// Compact operational shortcuts in the command-center header.
class InventoryHeaderQuickActions extends StatelessWidget {
  const InventoryHeaderQuickActions({super.key, required this.stockRoute});

  final String stockRoute;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderIconAction(
          icon: Icons.download_rounded,
          tooltip: 'Receive stock',
          color: AppColors.success,
          onTap: () => context.push(stockRoute),
        ),
        _HeaderIconAction(
          icon: Icons.upload_rounded,
          tooltip: 'Dispatch stock',
          color: AppColors.outbound,
          onTap: () => context.push(stockRoute),
        ),
        _HeaderIconAction(
          icon: Icons.swap_horiz_rounded,
          tooltip: 'Transfer stock',
          color: AppColors.info,
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
                      child: ColoredBox(color: AppColors.success),
                    ),
                  if (summary.lowStock > 0)
                    Expanded(
                      flex: (flex(summary.lowStock) * 1000).round().clamp(1, 1000),
                      child: ColoredBox(color: AppColors.warning),
                    ),
                  if (summary.outOfStock > 0)
                    Expanded(
                      flex: (flex(summary.outOfStock) * 1000).round().clamp(1, 1000),
                      child: ColoredBox(color: AppColors.error),
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
                color: AppColors.success,
                label: 'In Stock',
                count: summary.inStock,
              ),
              _HealthLegend(
                color: AppColors.warning,
                label: 'Low',
                count: summary.lowStock,
              ),
              _HealthLegend(
                color: AppColors.error,
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
                child: const Icon(
                  Icons.warehouse_outlined,
                  size: WmsIconSizes.status,
                  color: AppColors.primary,
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
                        child: const ColoredBox(color: AppColors.success),
                      ),
                    if (breakdown.low > 0)
                      Expanded(
                        flex: breakdown.low,
                        child: const ColoredBox(color: AppColors.warning),
                      ),
                    if (breakdown.out > 0)
                      Expanded(
                        flex: breakdown.out,
                        child: const ColoredBox(color: AppColors.error),
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
                  color: AppColors.success,
                ),
                _WarehouseStatPill(
                  label: 'Low',
                  count: breakdown.low,
                  color: AppColors.warning,
                ),
                _WarehouseStatPill(
                  label: 'Out',
                  count: breakdown.out,
                  color: AppColors.error,
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
    final stockRoute = InventoryUi.stockOpsRoute(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionChip(
            label: 'Receive',
            icon: Icons.download_rounded,
            color: AppColors.success,
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
            color: AppColors.info,
            onTap: () => context.push(stockRoute),
          ),
          const SizedBox(width: AppSpacing.xs),
          _ActionChip(
            label: 'View History',
            icon: Icons.history_rounded,
            color: AppColors.primary,
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
            color: AppColors.primary,
            selected: selected == null,
            onTap: () => onStockFilter(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          _StatusChip(
            label: 'In Stock',
            count: data.summary.inStock,
            color: AppColors.success,
            selected: selected == 'in',
            onTap: () => onStockFilter(selected == 'in' ? null : 'in'),
          ),
          const SizedBox(width: AppSpacing.xs),
          _StatusChip(
            label: 'Low Stock',
            count: data.summary.lowStock,
            color: AppColors.warning,
            selected: selected == 'low',
            onTap: () => onStockFilter(selected == 'low' ? null : 'low'),
          ),
          const SizedBox(width: AppSpacing.xs),
          _StatusChip(
            label: 'Out of Stock',
            count: data.summary.outOfStock,
            color: AppColors.error,
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
                  color: AppColors.info,
                  onTap: () => context.push(stockRoute),
                ),
                const SizedBox(width: AppSpacing.xs),
                _BulkActionChip(
                  label: 'Adjust',
                  icon: Icons.tune_rounded,
                  color: AppColors.accent,
                  onTap: () => context.push(stockRoute),
                ),
                const SizedBox(width: AppSpacing.xs),
                _BulkActionChip(
                  label: 'Export',
                  icon: Icons.ios_share_rounded,
                  color: AppColors.primary,
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

class InventorySortBar extends StatelessWidget {
  const InventorySortBar({
    super.key,
    required this.data,
    required this.onSort,
  });

  final InventoryViewState data;
  final ValueChanged<InventorySortField> onSort;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort by',
          style: WmsDesignTokens.supportingDense(context).copyWith(
                color: wms.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final field in InventorySortField.values) ...[
                if (field != InventorySortField.values.first)
                  const SizedBox(width: AppSpacing.xs),
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(field.icon, size: WmsIconSizes.listLeading),
                      const SizedBox(width: 4),
                      Text(field.label),
                      if (data.sortField == field) ...[
                        const SizedBox(width: 4),
                        Icon(
                          data.sortAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: WmsIconSizes.status,
                        ),
                      ],
                    ],
                  ),
                  selected: data.sortField == field,
                  onSelected: (_) => onSort(field),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: WmsDesignTokens.body(context).copyWith(
                        fontWeight: data.sortField == field
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class InventoryFilterPanel extends StatelessWidget {
  const InventoryFilterPanel({
    super.key,
    required this.data,
    required this.searchController,
    required this.onSearch,
    required this.onWarehouse,
    required this.onCategory,
    this.onStockFilter,
  });

  final InventoryViewState data;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onWarehouse;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?>? onStockFilter;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SearchBar(
            controller: searchController,
            hintText: 'Search product, SKU, barcode...',
            onChanged: onSearch,
            leading: Icon(Icons.search, size: WmsIconSizes.search),
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(wms.surfaceVariant),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            constraints: const BoxConstraints(minHeight: 44),
            textStyle: WidgetStatePropertyAll(
              Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (onStockFilter != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Status',
              style: WmsDesignTokens.supportingDense(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            InventoryStatusChipBar(
              data: data,
              onStockFilter: onStockFilter!,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Warehouse',
            style: WmsDesignTokens.supportingDense(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InventoryWarehouseChipBar(
            warehouses: data.warehouses,
            selectedId: data.warehouseId,
            onSelected: onWarehouse,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Category',
            style: WmsDesignTokens.supportingDense(context).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterChipRow(
            options: data.allCategories,
            selected: data.categoryFilter,
            allLabel: 'All Categories',
            onSelected: onCategory,
          ),
        ],
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

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.allLabel,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _M3FilterChip(
            label: allLabel,
            selected: selected == null || selected!.isEmpty,
            onTap: () => onSelected(null),
          ),
          for (final option in options) ...[
            const SizedBox(width: AppSpacing.xs),
            _M3FilterChip(
              label: option,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
          ],
        ],
      ),
    );
  }
}

class _M3FilterChip extends StatelessWidget {
  const _M3FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, maxLines: 1, softWrap: false),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: WmsDesignTokens.body(context).copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class InventoryProductCard extends StatelessWidget {
  const InventoryProductCard({
    super.key,
    required this.item,
    required this.category,
    required this.lastUpdated,
    required this.availableQuantity,
    required this.reservedQuantity,
    required this.damagedQuantity,
    required this.batchLabel,
    required this.onTap,
    this.selected = false,
    this.selectionMode = false,
    this.onSelected,
  });

  final InventoryItem item;
  final String category;
  final DateTime? lastUpdated;
  final num availableQuantity;
  final num reservedQuantity;
  final num damagedQuantity;
  final String batchLabel;
  final VoidCallback onTap;
  final bool selected;
  final bool selectionMode;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final displayStatus = InventoryUi.displayStatus(item);
    final accent = InventoryUi.indicatorColor(displayStatus);

    return AppCard(
      onTap: selectionMode ? () => onSelected?.call(!selected) : onTap,
      elevated: true,
      accentColor: selected ? AppColors.primary : accent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode) ...[
                Checkbox(
                  value: selected,
                  onChanged: (v) => onSelected?.call(v ?? false),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WmsDesignTokens.cardTitle(context).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'SKU: ${item.sku}',
            style: WmsDesignTokens.body(context).copyWith(
              color: wms.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (category.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              category,
              style: WmsDesignTokens.supporting(context).copyWith(
                color: wms.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _MobileProductField(
            label: 'Warehouse',
            value: item.warehouseName,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Flexible(
                child: _MobileProductField(
                  label: 'Qty',
                  value: WmsFormatters.quantity(item.quantity),
                ),
              ),
              Flexible(
                child: _MobileProductField(
                  label: 'Available',
                  value: WmsFormatters.quantity(availableQuantity),
                  valueColor: availableQuantity > 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Flexible(
                child: _MobileProductField(
                  label: 'Reserved',
                  value: WmsFormatters.quantity(reservedQuantity),
                ),
              ),
              Flexible(
                child: _MobileProductField(
                  label: 'Damaged',
                  value: WmsFormatters.quantity(damagedQuantity),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Status:',
                style: WmsDesignTokens.supporting(context).copyWith(
                  color: wms.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: WmsStockStatusBadge(
                  status: displayStatus,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MobileProductField(label: 'Batch', value: batchLabel),
          if (item.expiryDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _MobileProductField(
              label: 'Expiry Date',
              value: WmsFormatters.notificationTimestamp(item.expiryDate),
              valueColor: InventoryUi.isExpired(item)
                  ? InventoryUi.expiredPurple
                  : null,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _MobileProductField(
            label: 'Updated',
            value: lastUpdated != null
                ? WmsFormatters.relativeTime(lastUpdated)
                : '—',
          ),
        ],
      ),
    );
  }
}

class _MobileProductField extends StatelessWidget {
  const _MobileProductField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: WmsDesignTokens.supportingDense(context).copyWith(
            color: wms.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: WmsDesignTokens.body(context).copyWith(
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
                  color: AppColors.success,
                ),
                _SummaryMetricRow(
                  'Low Stock',
                  '${data.summary.lowStock}',
                  color: AppColors.warning,
                ),
                _SummaryMetricRow(
                  'Out of Stock',
                  '${data.summary.outOfStock}',
                  color: AppColors.error,
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
