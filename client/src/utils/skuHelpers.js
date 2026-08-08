import { api } from '../api/client';

/**
 * Fetch the next auto-generated SKU for a product category (create flow only).
 */
export async function fetchNextSkuForCategory(categoryId) {
  if (!categoryId) return { sku: '', prefix: '' };
  const { data } = await api.get('/products/next-sku', {
    params: { category_id: categoryId },
  });
  return {
    sku: data.sku || '',
    prefix: data.prefix || '',
    categoryName: data.category_name || '',
  };
}
