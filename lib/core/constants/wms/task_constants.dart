/// Mirrors `server/constants/tasks.js` and web `TaskBadges.jsx`.
abstract final class WmsTaskStatuses {
  static const pending = 'Pending';
  static const accepted = 'Accepted';
  static const inProgress = 'In Progress';
  static const waitingConfirmation = 'Waiting Confirmation';
  static const completed = 'Completed';
  static const rejected = 'Rejected';
  static const overdue = 'Overdue';

  static const all = [
    pending,
    accepted,
    inProgress,
    waitingConfirmation,
    completed,
    rejected,
    overdue,
  ];

  static const filterPills = [
    pending,
    accepted,
    inProgress,
    completed,
    overdue,
    rejected,
  ];

  static String displayLabel(String status) {
    if (status == waitingConfirmation) return 'Awaiting';
    return status;
  }
}

abstract final class WmsTaskPriorities {
  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';
  static const critical = 'critical';

  static const all = [low, medium, high, critical];
}

abstract final class WmsTaskTypes {
  static const inventoryReceive = 'Inventory Receive';
  static const stockTransfer = 'Stock Transfer';
  static const outboundDispatch = 'Outbound Dispatch';
  static const orderPacking = 'Order Packing';
  static const inventoryCount = 'Inventory Count';
  static const stockAdjustment = 'Stock Adjustment';
  static const inspection = 'Inspection';
  static const cleaning = 'Cleaning';

  /// Create-task form options (web-parity labels).
  static const createFormTypes = [
    inventoryReceive,
    stockTransfer,
    'Warehouse Transfer',
    cleaning,
    'Audit',
    'Maintenance',
  ];

  /// Maps mobile form labels to API `task_type` values.
  static String toApiType(String formType) {
    switch (formType) {
      case 'Audit':
        return inventoryCount;
      case 'Maintenance':
        return inspection;
      default:
        return formType;
    }
  }

  static bool requiresProduct(String formType) {
    final api = toApiType(formType);
    return api == inventoryReceive || api == stockTransfer || formType == 'Warehouse Transfer';
  }

  static bool requiresQuantity(String formType) => requiresProduct(formType);

  static bool requiresToWarehouse(String formType) =>
      toApiType(formType) == stockTransfer || formType == 'Warehouse Transfer';

  static bool requiresSupplier(String formType) =>
      toApiType(formType) == inventoryReceive;

  /// Filter chips aligned with enterprise web workflow UI.
  static const filterTypes = [
    cleaning,
    inventoryReceive,
    stockTransfer,
    'Warehouse Transfer',
    'Audit',
    'Maintenance',
    outboundDispatch,
    inventoryCount,
    stockAdjustment,
    inspection,
    orderPacking,
  ];
}
