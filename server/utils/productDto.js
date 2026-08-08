const { formatCreatedBy } = require('./createdByDto');
const { sanitizeImageUrl } = require('./productImageStorage');

/**
 * API shape aligned with thesis spec (snake_case) plus populated category name.
 */
function formatProduct(doc) {
  if (!doc) return null;

  const category =
    doc.categoryId && typeof doc.categoryId === 'object' && doc.categoryId.name
      ? {
          id: doc.categoryId._id?.toString(),
          name: doc.categoryId.name,
        }
      : null;

  return {
    id: doc._id?.toString(),
    sku: doc.sku,
    name: doc.name,
    description: doc.description ?? '',
    category_id: doc.categoryId?._id?.toString() || doc.categoryId?.toString() || null,
    category,
    unit_cost: doc.unitCost,
    unit_price: doc.unitPrice,
    min_stock_threshold: doc.minStockThreshold,
    barcode: doc.barcode ?? '',
    image_url: sanitizeImageUrl(doc.imageUrl ?? ''),
    created_at: doc.createdAt,
    updated_at: doc.updatedAt,
    created_by: formatCreatedBy(doc),
  };
}

function parseProductBody(body) {
  const sku = body.sku ?? body.SKU;
  const name = body.name;
  const description = body.description;
  const categoryId = body.category_id ?? body.categoryId;
  const unitCost = body.unit_cost ?? body.unitCost;
  const unitPrice = body.unit_price ?? body.unitPrice;
  const minStockThreshold = body.min_stock_threshold ?? body.minStockThreshold;
  const barcode = body.barcode;
  const imageUrl = body.image_url ?? body.imageUrl;

  return {
    sku,
    name,
    description,
    categoryId,
    unitCost,
    unitPrice,
    minStockThreshold,
    barcode,
    imageUrl,
  };
}

module.exports = { formatProduct, parseProductBody };
