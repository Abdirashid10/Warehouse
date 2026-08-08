const mongoose = require('mongoose');

/** Collection names (Mongoose default pluralization). */
const COLLECTIONS = {
  users: 'users',
  products: 'products',
  warehouses: 'warehouses',
  categories: 'categories',
  inventories: 'inventories',
  movements: 'movements',
};

/**
 * $lookup + $unwind with preserveNullAndEmptyArrays (SQL LEFT JOIN behaviour).
 */
function leftJoin(localField, from, as) {
  return [
    {
      $lookup: {
        from,
        localField,
        foreignField: '_id',
        as,
      },
    },
    {
      $unwind: {
        path: `$${as}`,
        preserveNullAndEmptyArrays: true,
      },
    },
  ];
}

function formatUserDoc(user) {
  if (!user || !user.username) return null;
  return {
    id: user._id?.toString(),
    name: user.username,
    role: user.role,
  };
}

function formatProductLean(p) {
  if (!p || !p._id) return null;
  const category =
    p.category && p.category.name
      ? { id: p.category._id?.toString(), name: p.category.name }
      : p.categoryId && typeof p.categoryId === 'object' && p.categoryId.name
        ? { id: p.categoryId._id?.toString(), name: p.categoryId.name }
        : null;

  return {
    id: p._id.toString(),
    _id: p._id.toString(),
    sku: p.sku || '—',
    name: p.name || '—',
    description: p.description ?? '',
    category,
    min_stock_threshold: p.minStockThreshold ?? 0,
    minStockThreshold: p.minStockThreshold ?? 0,
    unit_cost: p.unitCost,
    unit_price: p.unitPrice,
    barcode: p.barcode ?? '',
    image_url: p.imageUrl ?? '',
    created_by: formatUserDoc(p.creator || p.createdBy),
  };
}

module.exports = {
  COLLECTIONS,
  leftJoin,
  formatUserDoc,
  formatProductLean,
};
