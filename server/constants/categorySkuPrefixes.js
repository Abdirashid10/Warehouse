/**
 * Category name → SKU prefix mapping (case-insensitive match on normalized name).
 * @see requirements: ELE, FOD, FUR, OFF, CLO, WEQ, STA
 */
const CATEGORY_SKU_PREFIX_BY_NAME = {
  electronics: 'ELE',
  food: 'FOD',
  furniture: 'FUR',
  'office supplies': 'OFF',
  clothing: 'CLO',
  'warehouse equipment': 'WEQ',
  stationery: 'STA',
};

const MIN_SKU_SEQUENCE_DIGITS = 3;

function normalizeCategoryName(name) {
  return String(name || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

/**
 * Resolve a 3-letter SKU prefix for a category display name.
 * Known categories use the enterprise map; others use the first three letters (A–Z0–9).
 */
function getSkuPrefixForCategoryName(categoryName) {
  const normalized = normalizeCategoryName(categoryName);
  if (CATEGORY_SKU_PREFIX_BY_NAME[normalized]) {
    return CATEGORY_SKU_PREFIX_BY_NAME[normalized];
  }
  const letters = String(categoryName || '')
    .replace(/[^a-zA-Z0-9]/g, '')
    .toUpperCase();
  if (letters.length >= 3) return letters.slice(0, 3);
  return (letters + 'XXX').slice(0, 3);
}

module.exports = {
  CATEGORY_SKU_PREFIX_BY_NAME,
  MIN_SKU_SEQUENCE_DIGITS,
  normalizeCategoryName,
  getSkuPrefixForCategoryName,
};
