const mongoose = require('mongoose');
const { Inventory } = require('../models');
const {
  COLLECTIONS,
  leftJoin,
  formatUserDoc,
  formatProductLean,
} = require('../utils/lookupHelpers');
const { applyStockStatusToRow, enrichInventoryRows, summarizeInventoryRows } = require('../utils/stockStatus');
const { applyExpiryStatusToRow, summarizeExpiryRows } = require('../utils/expiryStatus');
const {
  CONDITION_AVAILABLE,
  CONDITION_DAMAGED,
  CONDITION_INSPECTION,
} = require('../constants/inventoryConditions');

function buildInventoryTrackingPipeline({ warehouseId, warehouseIds } = {}) {
  const matchStage = {};
  if (warehouseId && mongoose.Types.ObjectId.isValid(warehouseId)) {
    matchStage.warehouseId = new mongoose.Types.ObjectId(warehouseId);
  } else if (Array.isArray(warehouseIds) && warehouseIds.length > 0) {
    const ids = warehouseIds
      .filter((id) => mongoose.Types.ObjectId.isValid(id))
      .map((id) => new mongoose.Types.ObjectId(id));
    if (ids.length) matchStage.warehouseId = { $in: ids };
  }

  return [
    ...(Object.keys(matchStage).length ? [{ $match: matchStage }] : []),
    {
      $group: {
        _id: { productId: '$productId', warehouseId: '$warehouseId' },
        currentQuantity: { $sum: '$quantity' },
        availableStock: {
          $sum: {
            $cond: [{ $eq: ['$condition', CONDITION_AVAILABLE] }, '$quantity', 0],
          },
        },
        damagedStock: {
          $sum: {
            $cond: [{ $eq: ['$condition', CONDITION_DAMAGED] }, '$quantity', 0],
          },
        },
        reservedStock: {
          $sum: {
            $cond: [{ $eq: ['$condition', CONDITION_INSPECTION] }, '$quantity', 0],
          },
        },
        lastUpdated: { $max: '$updatedAt' },
        createdBy: { $first: '$createdBy' },
        batchNumber: { $first: '$batchNumber' },
        manufactureDate: { $first: '$manufactureDate' },
        expiryDate: { $min: '$expiryDate' },
      },
    },
    ...leftJoin('_id.productId', COLLECTIONS.products, 'product'),
    ...leftJoin('_id.warehouseId', COLLECTIONS.warehouses, 'warehouse'),
    ...leftJoin('createdBy', COLLECTIONS.users, 'creator'),
    {
      $lookup: {
        from: COLLECTIONS.categories,
        localField: 'product.categoryId',
        foreignField: '_id',
        as: 'category',
      },
    },
    { $unwind: { path: '$category', preserveNullAndEmptyArrays: true } },
    { $sort: { lastUpdated: -1 } },
  ];
}

function resolveProductName(product, productId) {
  const name = product?.name;
  if (name && name !== '—') return name;
  if (productId) return 'Deleted Product';
  return 'Deleted Product';
}

function resolveWarehouseName(warehouse, warehouseId) {
  const name = warehouse?.name;
  if (name) return name;
  if (warehouseId) return 'Deleted Warehouse';
  return 'Deleted Warehouse';
}

function mapInventoryTrackingRow(row) {
  const product = row.product
    ? formatProductLean({
        ...row.product,
        category: row.category,
      })
    : null;
  const productId = row._id.productId?.toString();
  const warehouseId = row._id.warehouseId?.toString();
  const productName = resolveProductName(product, productId);
  const warehouseName = resolveWarehouseName(row.warehouse, warehouseId);

  const base = {
    id: `${row._id.productId}_${row._id.warehouseId}`,
    product_id: productId,
    warehouse_id: warehouseId,
    product: product
      ? { ...product, name: productName }
      : productId
        ? { id: productId, name: productName, sku: '—' }
        : null,
    warehouse: row.warehouse
      ? {
          id: row.warehouse._id.toString(),
          name: warehouseName,
          location: row.warehouse.location,
        }
      : warehouseId
        ? { id: warehouseId, name: warehouseName, location: '' }
        : null,
    product_name: productName,
    warehouse_name: warehouseName,
    sku: product?.sku && product.sku !== '—' ? product.sku : '—',
    current_quantity: row.currentQuantity ?? 0,
    quantity: row.currentQuantity ?? 0,
    available_stock: row.availableStock ?? 0,
    available: row.availableStock ?? 0,
    reserved_stock: row.reservedStock ?? 0,
    damaged_stock: row.damagedStock ?? 0,
    min_stock_threshold: product?.min_stock_threshold ?? product?.minStockThreshold ?? 0,
    batch_number: row.batchNumber || '',
    manufacture_date: row.manufactureDate || null,
    expiry_date: row.expiryDate || null,
    last_updated: row.lastUpdated,
    created_by: formatUserDoc(row.creator),
  };

  return applyExpiryStatusToRow(applyStockStatusToRow(base));
}

function filterInventoryTrackingRows(rows, q) {
  const query = (q || '').trim().toLowerCase();
  if (!query) return rows;

  return rows.filter((row) => {
    const product = row.product || {};
    const warehouse = row.warehouse || {};
    const hay = [product.sku, product.name, product.barcode, warehouse.name, row.stock_status]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();
    return hay.includes(query);
  });
}

/**
 * Aggregated product × warehouse inventory lines with unified stock status.
 */
async function fetchInventoryTrackingRows({ warehouseId, warehouseIds, q, expiryFilter } = {}) {
  const raw = await Inventory.aggregate(
    buildInventoryTrackingPipeline({ warehouseId, warehouseIds })
  );
  let mapped = enrichInventoryRows(raw.map(mapInventoryTrackingRow));
  mapped = filterInventoryTrackingRows(mapped, q);

  if (expiryFilter && expiryFilter !== 'all') {
    const filterMap = {
      expired: 'Expired',
      expiring_soon: 'Expiring Soon',
      expiring_30d: 'Expiring (30d)',
      safe: 'Safe',
      no_expiry: 'No Expiry',
    };
    const target = filterMap[expiryFilter];
    if (target) {
      mapped = mapped.filter((r) => r.expiry_status === target);
    }
  }

  const summary = summarizeInventoryRows(mapped);
  const expiry_summary = summarizeExpiryRows(mapped);

  return { rows: mapped, summary, expiry_summary };
}

module.exports = {
  buildInventoryTrackingPipeline,
  mapInventoryTrackingRow,
  filterInventoryTrackingRows,
  fetchInventoryTrackingRows,
  resolveProductName,
  resolveWarehouseName,
};
