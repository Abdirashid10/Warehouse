import 'package:flutter/material.dart';
import 'package:logisticsmobile/core/constants/wms/movement_constants.dart';
import 'package:logisticsmobile/core/constants/wms/order_constants.dart';
import 'package:logisticsmobile/core/constants/wms/stock_constants.dart';
import 'package:logisticsmobile/core/constants/wms/task_constants.dart';
import 'package:logisticsmobile/core/theme/wms_ui_colors.dart';

/// Theme-aware badge color pairs for status chips across modules.
abstract final class WmsBadgeColors {
  static ({Color fg, Color bg}) pair({
    required WmsUiColors colors,
    required Color fg,
    required Color bg,
  }) =>
      (fg: fg, bg: bg);

  static ({Color fg, Color bg}) taskStatus(WmsUiColors c, String status) {
    switch (status) {
      case WmsTaskStatuses.pending:
        return pair(colors: c, fg: c.textSecondary, bg: c.mutedSurface);
      case WmsTaskStatuses.accepted:
        return pair(colors: c, fg: c.info, bg: c.infoMuted);
      case WmsTaskStatuses.inProgress:
        return pair(colors: c, fg: c.processing, bg: c.processingMuted);
      case WmsTaskStatuses.waitingConfirmation:
        return pair(colors: c, fg: c.warning, bg: c.warningMuted);
      case WmsTaskStatuses.completed:
        return pair(colors: c, fg: c.success, bg: c.successMuted);
      case WmsTaskStatuses.rejected:
      case WmsTaskStatuses.overdue:
        return pair(colors: c, fg: c.error, bg: c.errorMuted);
      default:
        return pair(colors: c, fg: c.textSecondary, bg: c.mutedSurface);
    }
  }

  static ({Color fg, Color bg}) taskPriority(WmsUiColors c, String priority) {
    switch (priority.toLowerCase()) {
      case WmsTaskPriorities.low:
        return pair(colors: c, fg: c.textSecondary, bg: c.mutedSurface);
      case WmsTaskPriorities.high:
        return pair(colors: c, fg: c.outbound, bg: c.warningMuted);
      case WmsTaskPriorities.critical:
        return pair(colors: c, fg: c.error, bg: c.errorMuted);
      default:
        return pair(colors: c, fg: c.warning, bg: c.warningMuted);
    }
  }

  static ({Color fg, Color bg}) orderStatus(WmsUiColors c, String status) {
    switch (status) {
      case WmsOrderStatuses.pending:
        return pair(colors: c, fg: c.textSecondary, bg: c.mutedSurface);
      case WmsOrderStatuses.processing:
        return pair(colors: c, fg: c.processing, bg: c.processingMuted);
      case WmsOrderStatuses.packed:
        return pair(colors: c, fg: c.accent, bg: c.accentMuted);
      case WmsOrderStatuses.shipped:
        return pair(colors: c, fg: c.outbound, bg: c.warningMuted);
      case WmsOrderStatuses.delivered:
        return pair(colors: c, fg: c.success, bg: c.successMuted);
      default:
        if (status.toLowerCase() == 'cancelled') {
          return pair(colors: c, fg: c.error, bg: c.errorMuted);
        }
        return pair(colors: c, fg: c.textSecondary, bg: c.mutedSurface);
    }
  }

  static ({Color fg, Color bg}) stockStatus(WmsUiColors c, String status) {
    switch (status) {
      case WmsStockStatuses.inStock:
        return pair(colors: c, fg: c.success, bg: c.successMuted);
      case WmsStockStatuses.lowStock:
        return pair(colors: c, fg: c.warning, bg: c.warningMuted);
      case WmsStockStatuses.outOfStock:
        return pair(colors: c, fg: c.error, bg: c.errorMuted);
      case WmsStockStatuses.expired:
        return pair(colors: c, fg: c.expired, bg: c.expiredMuted);
      default:
        return pair(colors: c, fg: c.textSecondary, bg: c.mutedSurface);
    }
  }

  static ({Color fg, Color bg}) movementType(WmsUiColors c, String type) {
    switch (type) {
      case WmsMovementTypes.inbound:
        return pair(colors: c, fg: c.success, bg: c.successMuted);
      case WmsMovementTypes.outbound:
        return pair(colors: c, fg: c.outbound, bg: c.warningMuted);
      case WmsMovementTypes.transfer:
        return pair(colors: c, fg: c.info, bg: c.infoMuted);
      case WmsMovementTypes.adjustment:
        return pair(colors: c, fg: c.accent, bg: c.accentMuted);
      case WmsMovementTypes.returnType:
        return pair(
          colors: c,
          fg: c.isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
          bg: c.isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
        );
      default:
        return pair(colors: c, fg: c.textSecondary, bg: c.mutedSurface);
    }
  }
}
