import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/theme/app_colors.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/widgets/app_button.dart';
import 'package:logisticsmobile/widgets/app_card.dart';
import 'package:logisticsmobile/widgets/connectivity_scope.dart';
import 'package:logisticsmobile/widgets/wms/wms_skeleton.dart';

/// Enterprise error categories for consistent failure presentation.
enum WmsErrorKind {
  network,
  apiFailure,
  sessionExpired,
  permissionDenied,
}

class WmsEmptyState extends StatelessWidget {
  const WmsEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final primary = Theme.of(context).colorScheme.primary;
    final padding = compact ? AppSpacing.lg : AppSpacing.xxl;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: AppCard(
          elevated: true,
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
                decoration: BoxDecoration(
                  color: wms.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(
                  icon,
                  size: compact
                      ? WmsIconSizes.emptyState - 16
                      : WmsIconSizes.emptyState,
                  color: primary,
                ),
              ),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: wms.textSecondary,
                        height: 1.35,
                      ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: actionLabel!,
                  fullWidth: false,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Preset enterprise empty states for core modules.
abstract final class WmsEmptyStates {
  static Widget orders({VoidCallback? onClearFilters}) => WmsEmptyState(
        title: 'No Orders',
        message:
            'No orders match your current filters. Adjust search or status filters to see more results.',
        icon: Icons.shopping_cart_outlined,
        actionLabel: onClearFilters != null ? 'Clear filters' : null,
        onAction: onClearFilters,
      );

  static Widget inventory({VoidCallback? onClearFilters}) => WmsEmptyState(
        title: 'No Inventory',
        message:
            'No products match your search or warehouse filters. Try a different query or location.',
        icon: Icons.inventory_2_outlined,
        actionLabel: onClearFilters != null ? 'Clear filters' : null,
        onAction: onClearFilters,
      );

  static Widget notifications({String? message}) => WmsEmptyState(
        title: 'No Notifications',
        message: message ?? "You don't have any notifications yet.",
        icon: Icons.notifications_outlined,
      );

  static Widget tasks({VoidCallback? onClearFilters}) => WmsEmptyState(
        title: 'No Tasks',
        message:
            'No tasks match your current filters. Check back later or adjust your view.',
        icon: Icons.assignment_outlined,
        actionLabel: onClearFilters != null ? 'Clear filters' : null,
        onAction: onClearFilters,
      );
}

class WmsErrorState extends StatelessWidget {
  const WmsErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.showCachedHint = false,
    this.kind,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? title;
  final bool showCachedHint;
  final WmsErrorKind? kind;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final isOffline = !ConnectivityScope.isOnline(context);
    final resolvedKind = kind ??
        (isOffline ? WmsErrorKind.network : WmsErrorKind.apiFailure);

    final heading = title ?? _titleForKind(resolvedKind);
    final body = _messageForKind(resolvedKind, message);
    final icon = _iconForKind(resolvedKind);
    final iconColor = _colorForKind(resolvedKind, wms);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: AppCard(
          elevated: true,
          accentColor: iconColor,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(WmsIconSizes.iconCardPadding),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: WmsIconSizes.emptyState, color: iconColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                heading,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: wms.textSecondary,
                      height: 1.35,
                    ),
              ),
              if (showCachedHint) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Showing last successful sync.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: wms.info,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: _retryLabel(resolvedKind),
                  fullWidth: false,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _titleForKind(WmsErrorKind kind) {
    switch (kind) {
      case WmsErrorKind.network:
        return 'Network Error';
      case WmsErrorKind.apiFailure:
        return 'Unable to Load Data';
      case WmsErrorKind.sessionExpired:
        return 'Session Expired';
      case WmsErrorKind.permissionDenied:
        return 'Permission Denied';
    }
  }

  static String _messageForKind(WmsErrorKind kind, String fallback) {
    switch (kind) {
      case WmsErrorKind.network:
        return 'Check your internet connection and try again. Previously loaded data may still be available on other screens.';
      case WmsErrorKind.apiFailure:
        return fallback;
      case WmsErrorKind.sessionExpired:
        return 'Your secure session has ended. Sign in again to continue warehouse operations.';
      case WmsErrorKind.permissionDenied:
        return 'You do not have permission to access this resource. Contact your warehouse administrator if you need access.';
    }
  }

  static IconData _iconForKind(WmsErrorKind kind) {
    switch (kind) {
      case WmsErrorKind.network:
        return Icons.wifi_off_rounded;
      case WmsErrorKind.apiFailure:
        return Icons.cloud_off_outlined;
      case WmsErrorKind.sessionExpired:
        return Icons.lock_clock_outlined;
      case WmsErrorKind.permissionDenied:
        return Icons.block_outlined;
    }
  }

  static Color _colorForKind(WmsErrorKind kind, WmsThemeExtension wms) {
    switch (kind) {
      case WmsErrorKind.network:
        return wms.warning;
      case WmsErrorKind.apiFailure:
        return wms.error;
      case WmsErrorKind.sessionExpired:
        return AppColors.info;
      case WmsErrorKind.permissionDenied:
        return wms.error;
    }
  }

  static String _retryLabel(WmsErrorKind kind) {
    switch (kind) {
      case WmsErrorKind.network:
        return 'Retry when online';
      case WmsErrorKind.sessionExpired:
        return 'Sign in again';
      default:
        return 'Try again';
    }
  }
}

/// Detect error kind from common API message patterns (UI-only).
WmsErrorKind? wmsErrorKindFromMessage(String? message) {
  if (message == null || message.isEmpty) return null;
  final lower = message.toLowerCase();
  if (lower.contains('401') ||
      lower.contains('unauthorized') ||
      lower.contains('session') && lower.contains('expir')) {
    return WmsErrorKind.sessionExpired;
  }
  if (lower.contains('403') ||
      lower.contains('forbidden') ||
      lower.contains('permission')) {
    return WmsErrorKind.permissionDenied;
  }
  return null;
}

class WmsLoadingState extends StatelessWidget {
  const WmsLoadingState({
    super.key,
    this.message = 'Loading…',
    this.showProgress = true,
  });

  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress) ...[
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ] else
              const WmsKpiSkeleton(),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: wms.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class WmsSectionHeader extends StatelessWidget {
  const WmsSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.count,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: WmsDesignTokens.sectionAccentBarWidth,
          height: WmsDesignTokens.sectionAccentBarHeight,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: WmsDesignTokens.sectionTitle(context)),
              ),
              if (count != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: wms.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '$count',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class WmsSearchField extends StatelessWidget {
  const WmsSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search, size: WmsIconSizes.search),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

class WmsFilterChipBar extends StatelessWidget {
  const WmsFilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.allLabel = 'All',
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
          _chip(context, allLabel, selected == null || selected!.isEmpty, () {
            onSelected(null);
          }),
          for (final option in options) ...[
            const SizedBox(width: AppSpacing.sm),
            _chip(context, option, selected == option, () {
              onSelected(option);
            }),
          ],
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: WmsDesignTokens.minReadableFontSize + 1,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
