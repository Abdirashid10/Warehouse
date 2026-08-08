const mongoose = require('mongoose');
const { Product, Category, Inventory } = require('../models');
const { formatProduct, parseProductBody } = require('../utils/productDto');
const {
  sanitizeImageUrl,
  deleteProductImageFile,
  publicUrlFromFilename,
} = require('../utils/productImageStorage');
const {
  allocateNextSku,
  getNextSkuForCategory,
} = require('../utils/skuGenerator');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

async function validateCategoryId(categoryId) {
  if (!categoryId || !isValidObjectId(categoryId)) {
    return { error: 'Valid category_id is required' };
  }
  const cat = await Category.findById(categoryId);
  if (!cat) {
    return { error: 'Category not found' };
  }
  return { category: cat };
}

function validateProductFields(fields, { requireAll = true, isCreate = false } = {}) {
  const { sku, name, categoryId, unitCost, unitPrice, minStockThreshold } = fields;

  if (!isCreate && sku !== undefined) {
    if (!sku || typeof sku !== 'string' || !String(sku).trim()) {
      return 'sku cannot be empty';
    }
  }
  if (requireAll || name !== undefined) {
    if (!name || typeof name !== 'string' || !String(name).trim()) {
      return 'name is required';
    }
  }
  if (requireAll || categoryId !== undefined) {
    if (!categoryId) {
      return 'category_id is required';
    }
  }
  if (requireAll || unitCost !== undefined) {
    const cost = Number(unitCost);
    if (!Number.isFinite(cost) || cost < 0) {
      return 'unit_cost must be a non-negative number';
    }
  }
  if (requireAll || unitPrice !== undefined) {
    const price = Number(unitPrice);
    if (!Number.isFinite(price) || price < 0) {
      return 'unit_price must be a non-negative number';
    }
  }
  if (minStockThreshold !== undefined && minStockThreshold !== null && minStockThreshold !== '') {
    const t = Number(minStockThreshold);
    if (!Number.isFinite(t) || t < 0) {
      return 'min_stock_threshold must be a non-negative number';
    }
  }
  return null;
}

const { CREATED_BY_SELECT } = require('../utils/createdByDto');

const productPopulate = [
  { path: 'categoryId', select: 'name description' },
  { path: 'createdBy', select: CREATED_BY_SELECT },
];

async function listProducts(req, res) {
  try {
    const q = (req.query.q || '').trim();
    const filter = {};
    if (q) {
      filter.$or = [
        { sku: new RegExp(q, 'i') },
        { name: new RegExp(q, 'i') },
        { description: new RegExp(q, 'i') },
        { barcode: new RegExp(q, 'i') },
      ];
    }

    const products = await Product.find(filter)
      .populate(productPopulate)
      .sort({ sku: 1 })
      .lean();

    const formatted = products.map(formatProduct);

    const inventoryAgg = await Inventory.aggregate([
      { $group: {
        _id: '$productId',
        total_stock: { $sum: '$quantity' },
        warehouse_count: { $addToSet: '$warehouseId' },
        earliest_expiry: { $min: '$expiryDate' },
      }},
      { $project: {
        total_stock: 1,
        warehouse_count: { $size: '$warehouse_count' },
        earliest_expiry: 1,
      }},
    ]);

    const stockMap = {};
    for (const row of inventoryAgg) {
      stockMap[row._id.toString()] = row;
    }

    const now = new Date();
    const soon = new Date(Date.now() + 30 * 86400000);
    let lowStockCount = 0;
    let outOfStockCount = 0;
    let expiringCount = 0;
    let totalValue = 0;

    for (const p of formatted) {
      const inv = stockMap[p.id] || { total_stock: 0, warehouse_count: 0, earliest_expiry: null };
      p.total_stock = inv.total_stock;
      p.warehouse_count = inv.warehouse_count;
      p.earliest_expiry = inv.earliest_expiry;

      if (inv.total_stock === 0 && inv.warehouse_count > 0) outOfStockCount++;
      else if (inv.total_stock > 0 && inv.total_stock <= (p.min_stock_threshold || 0)) lowStockCount++;

      if (inv.earliest_expiry && new Date(inv.earliest_expiry) <= soon) expiringCount++;

      totalValue += (p.unit_price || 0) * inv.total_stock;
    }

    return res.json({
      products: formatted,
      summary: {
        total: formatted.length,
        categories: [...new Set(formatted.map((p) => p.category_id).filter(Boolean))].length,
        low_stock: lowStockCount,
        out_of_stock: outOfStockCount,
        expiring: expiringCount,
        total_value: Math.round(totalValue * 100) / 100,
      },
    });
  } catch (err) {
    console.error('listProducts error:', err.message);
    return res.status(500).json({ message: 'Failed to load products' });
  }
}

async function previewNextSku(req, res) {
  try {
    const categoryId = req.query.category_id ?? req.query.categoryId;
    if (!categoryId || !isValidObjectId(categoryId)) {
      return res.status(400).json({ message: 'Valid category_id is required' });
    }

    const catCheck = await validateCategoryId(categoryId);
    if (catCheck.error) {
      return res.status(400).json({ message: catCheck.error });
    }

    const { sku, prefix } = await getNextSkuForCategory(
      categoryId,
      catCheck.category.name
    );

    return res.json({
      sku,
      prefix,
      category_id: categoryId,
      category_name: catCheck.category.name,
    });
  } catch (err) {
    console.error('previewNextSku error:', err.message);
    return res.status(500).json({ message: 'Failed to generate SKU preview' });
  }
}

async function getProduct(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid product id' });
    }

    const product = await Product.findById(id).populate(productPopulate).lean();
    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    return res.json({ product: formatProduct(product) });
  } catch (err) {
    console.error('getProduct error:', err.message);
    return res.status(500).json({ message: 'Failed to load product' });
  }
}

async function createProduct(req, res) {
  try {
    const parsed = parseProductBody(req.body);
    const validationError = validateProductFields(parsed, {
      requireAll: true,
      isCreate: true,
    });
    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    const catCheck = await validateCategoryId(parsed.categoryId);
    if (catCheck.error) {
      return res.status(400).json({ message: catCheck.error });
    }

    const sku = await allocateNextSku(parsed.categoryId, catCheck.category.name);

    const product = await Product.create({
      sku,
      name: String(parsed.name).trim(),
      description: parsed.description != null ? String(parsed.description) : '',
      categoryId: parsed.categoryId,
      unitCost: Number(parsed.unitCost),
      unitPrice: Number(parsed.unitPrice),
      minStockThreshold:
        parsed.minStockThreshold != null ? Number(parsed.minStockThreshold) : 0,
      barcode: parsed.barcode != null ? String(parsed.barcode).trim() : '',
      imageUrl: sanitizeImageUrl(parsed.imageUrl),
      createdBy: req.user.id,
    });

    const populated = await Product.findById(product._id).populate(productPopulate).lean();
    return res.status(201).json({ product: formatProduct(populated) });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ message: 'SKU already exists' });
    }
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    console.error('createProduct error:', err.message);
    return res.status(500).json({ message: 'Failed to create product' });
  }
}

async function updateProduct(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid product id' });
    }

    const product = await Product.findById(id);
    if (!product) {
      return res.status(404).json({ message: 'Product not found' });
    }

    const parsed = parseProductBody(req.body);
    const validationError = validateProductFields(parsed, { requireAll: false });
    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    if (parsed.sku !== undefined && String(parsed.sku).trim() !== product.sku) {
      return res.status(400).json({
        message: 'SKU cannot be changed after the product is created',
      });
    }
    if (parsed.name !== undefined) product.name = String(parsed.name).trim();
    if (parsed.description !== undefined) product.description = String(parsed.description);
    if (parsed.categoryId !== undefined) {
      const catCheck = await validateCategoryId(parsed.categoryId);
      if (catCheck.error) {
        return res.status(400).json({ message: catCheck.error });
      }
      product.categoryId = parsed.categoryId;
    }
    if (parsed.unitCost !== undefined) product.unitCost = Number(parsed.unitCost);
    if (parsed.unitPrice !== undefined) product.unitPrice = Number(parsed.unitPrice);
    if (parsed.minStockThreshold !== undefined) {
      product.minStockThreshold = Number(parsed.minStockThreshold);
    }
    if (parsed.barcode !== undefined) product.barcode = String(parsed.barcode).trim();
    if (parsed.imageUrl !== undefined) {
      const nextUrl = sanitizeImageUrl(parsed.imageUrl);
      if (product.imageUrl && product.imageUrl !== nextUrl) {
        deleteProductImageFile(product.imageUrl);
      }
      product.imageUrl = nextUrl;
    }

    await product.save();

    const populated = await Product.findById(id).populate(productPopulate).lean();
    return res.json({ product: formatProduct(populated) });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ message: 'SKU already exists' });
    }
    console.error('updateProduct error:', err.message);
    return res.status(500).json({ message: 'Failed to update product' });
  }
}

async function deleteProduct(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid product id' });
    }

    const stock = await Inventory.countDocuments({ productId: id });
    if (stock > 0) {
      return res.status(400).json({
        message: 'Cannot delete a product that still has inventory records. Clear stock first.',
      });
    }

    const deleted = await Product.findByIdAndDelete(id);
    if (!deleted) {
      return res.status(404).json({ message: 'Product not found' });
    }

    if (deleted.imageUrl) {
      deleteProductImageFile(deleted.imageUrl);
    }

    return res.json({ message: 'Product deleted' });
  } catch (err) {
    console.error('deleteProduct error:', err.message);
    return res.status(500).json({ message: 'Failed to delete product' });
  }
}

async function uploadProductImage(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Image file is required' });
    }
    const image_url = publicUrlFromFilename(req.file.filename);
    return res.status(201).json({ image_url });
  } catch (err) {
    console.error('uploadProductImage error:', err.message);
    return res.status(500).json({ message: 'Failed to upload image' });
  }
}

module.exports = {
  listProducts,
  previewNextSku,
  getProduct,
  createProduct,
  updateProduct,
  deleteProduct,
  uploadProductImage,
};
