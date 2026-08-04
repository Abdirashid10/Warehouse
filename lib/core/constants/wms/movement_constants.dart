/// Stock movement types — web `StockMovementsPage.jsx`.
abstract final class WmsMovementTypes {
  static const inbound = 'INBOUND';
  static const outbound = 'OUTBOUND';
  static const transfer = 'TRANSFER';
  static const adjustment = 'ADJUSTMENT';
  static const returnType = 'RETURN';

  static const all = [inbound, outbound, transfer, adjustment, returnType];

  static String label(String type) {
    switch (type) {
      case inbound:
        return 'Inbound';
      case outbound:
        return 'Outbound';
      case transfer:
        return 'Transfer';
      case adjustment:
        return 'Adjustment';
      case returnType:
        return 'Return';
      default:
        return type;
    }
  }

  /// Staff inventory quick-action labels.
  static String staffActionLabel(String type) {
    switch (type) {
      case inbound:
        return 'Receive';
      case outbound:
        return 'Dispatch';
      case transfer:
        return 'Transfer';
      default:
        return label(type);
    }
  }
}
