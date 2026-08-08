/// Mirrors web `stockStatus.js`.
abstract final class WmsStockStatuses {
  static const inStock = 'In Stock';
  static const lowStock = 'Low Stock';
  static const outOfStock = 'Out of Stock';
  static const expired = 'Expired';

  static const all = [inStock, lowStock, outOfStock, expired];
}
