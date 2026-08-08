/** Display category name from API product or populated inventory row. */
export function productCategoryName(product) {
  if (!product) return '—';
  return product.category?.name || product.categoryId?.name || '—';
}

export function formatMoney(n) {
  if (n == null || Number.isNaN(Number(n))) return '—';
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
  }).format(Number(n));
}
