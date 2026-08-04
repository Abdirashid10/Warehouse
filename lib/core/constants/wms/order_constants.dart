/// Mirrors `server/constants/orderStatus.js`.
abstract final class WmsOrderStatuses {
  static const pending = 'Pending';
  static const processing = 'Processing';
  static const packed = 'Packed';
  static const shipped = 'Shipped';
  static const delivered = 'Delivered';

  static const all = [pending, processing, packed, shipped, delivered];

  /// Staff workflow filter pills (web `STAFF_STATUSES`).
  static const staffFilters = [processing, packed, shipped];
}
