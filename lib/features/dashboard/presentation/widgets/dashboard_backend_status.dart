import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/config/api_config.dart';
import 'package:logisticsmobile/core/theme/app_spacing.dart';
import 'package:logisticsmobile/core/theme/wms_icon_sizes.dart';
import 'package:logisticsmobile/core/theme/wms_design_tokens.dart';
import 'package:logisticsmobile/core/theme/wms_theme_extension.dart';
import 'package:logisticsmobile/widgets/wms/wms_state_views.dart';

/// Shown when the command center cannot reach the Node.js backend.
class DashboardBackendError extends StatelessWidget {
  const DashboardBackendError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final apiUrl = ApiConfig.baseUrl;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WmsErrorState(message: message, onRetry: onRetry),
          const SizedBox(height: AppSpacing.lg),
          _ApiInfoCard(
            title: 'Backend URL',
            value: apiUrl,
            hint: 'Node.js server must expose /api/dashboard/stats and related routes.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ApiInfoCard(
            title: 'Environment',
            value: ApiConfig.environmentLabel,
            hint: kIsWeb
                ? 'Web: flutter run --dart-define=API_ENV=development'
                : 'Emulator: --dart-define=API_ENV=emulator\n'
                    'Phone: --dart-define=API_BASE_URL=http://LAN_IP:8000/api',
          ),
        ],
      ),
    );
  }
}

class DashboardBackendSyncBar extends StatelessWidget {
  const DashboardBackendSyncBar({
    super.key,
    this.lastSyncedAt,
    this.isSyncing = false,
  });

  final DateTime? lastSyncedAt;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    final syncText = lastSyncedAt != null
        ? 'Synced ${_relative(lastSyncedAt!)}'
        : 'Live from backend';

    return Material(
      color: wms.surfaceVariant.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              isSyncing ? Icons.sync : Icons.cloud_done_outlined,
              size: WmsIconSizes.status,
              color: wms.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                syncText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: wms.textSecondary,
                ),
              ),
            ),
            if (kDebugMode)
              Text(
                ApiConfig.baseUrl.replaceFirst('http://', ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WmsDesignTokens.supportingDense(context).copyWith(
                  color: wms.textTertiary,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _ApiInfoCard extends StatelessWidget {
  const _ApiInfoCard({
    required this.title,
    required this.value,
    required this.hint,
  });

  final String title;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final wms = context.wms;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: wms.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: wms.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: WmsDesignTokens.supportingDense(context)),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: WmsDesignTokens.body(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: WmsDesignTokens.supportingDense(context).copyWith(
              color: wms.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
