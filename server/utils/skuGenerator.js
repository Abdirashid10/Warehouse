const { Product } = require('../models');
const {
  MIN_SKU_SEQUENCE_DIGITS,
  getSkuPrefixForCategoryName,
} = require('../constants/categorySkuPrefixes');

const SKU_FORMAT_REGEX = /^[A-Z]{3}-\d+$/;

function buildSkuRegex(prefix) {
  return new RegExp(`^${prefix}-(\\d+)$`, 'i');
}

/**
 * Parse sequence number from SKUs matching PREFIX-### for the given prefix.
 */
function parseSkuSequence(sku, prefix) {
  const match = String(sku || '')
    .trim()
    .toUpperCase()
    .match(buildSkuRegex(prefix));
  if (!match) return null;
  const digits = match[1];
  const value = parseInt(digits, 10);
  if (!Number.isFinite(value) || value < 1) return null;
  return { value, digitLength: digits.length };
}

/**
 * Format the next SKU with at least MIN_SKU_SEQUENCE_DIGITS (expands for 1000+).
 */
function formatSku(prefix, sequence) {
  const digitLength = Math.max(
    MIN_SKU_SEQUENCE_DIGITS,
    String(sequence).length
  );
  return `${prefix}-${String(sequence).padStart(digitLength, '0')}`;
}

/**
 * Find the highest existing sequence for a category prefix among products in that category.
 */
function findMaxSequenceInCategory(products, prefix) {
  let maxSeq = 0;
  for (const doc of products) {
    const parsed = parseSkuSequence(doc.sku, prefix);
    if (parsed && parsed.value > maxSeq) {
      maxSeq = parsed.value;
    }
  }
  return maxSeq;
}

/**
 * Compute the next SKU for a category (does not persist).
 */
function computeNextSku(categoryName, productsInCategory) {
  const prefix = getSkuPrefixForCategoryName(categoryName);
  const maxSeq = findMaxSequenceInCategory(productsInCategory, prefix);
  const nextSeq = maxSeq + 1;
  return {
    sku: formatSku(prefix, nextSeq),
    prefix,
    sequence: nextSeq,
  };
}

async function loadProductsSkusForCategory(categoryId) {
  return Product.find({ categoryId }).select('sku').lean();
}

/**
 * Preview or allocate the next SKU for a category.
 */
async function getNextSkuForCategory(categoryId, categoryName) {
  const products = await loadProductsSkusForCategory(categoryId);
  return computeNextSku(categoryName, products);
}

/**
 * Allocate next SKU with retry on unique-index race (duplicate SKU).
 */
async function allocateNextSku(categoryId, categoryName, { maxAttempts = 8 } = {}) {
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    const products = await loadProductsSkusForCategory(categoryId);
    const { sku } = computeNextSku(categoryName, products);

    const existing = await Product.findOne({ sku }).select('_id').lean();
    if (!existing) {
      return sku;
    }
  }
  const err = new Error('Could not allocate a unique SKU. Please try again.');
  err.statusCode = 409;
  throw err;
}

function isGeneratedSkuFormat(sku) {
  return SKU_FORMAT_REGEX.test(String(sku || '').trim().toUpperCase());
}

module.exports = {
  SKU_FORMAT_REGEX,
  buildSkuRegex,
  parseSkuSequence,
  formatSku,
  computeNextSku,
  getNextSkuForCategory,
  allocateNextSku,
  isGeneratedSkuFormat,
  getSkuPrefixForCategoryName,
};
