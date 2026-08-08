const { Order } = require('../models');

const ORDER_PREFIX = 'ORD';
const LEGACY_PREFIX = 'NEX';
const ORDER_NUMBER_PATTERN = /^(ORD|NEX)-(\d{4})-(\d+)$/i;

/**
 * Build ORD-YYYY-### reference (3-digit sequence).
 */
function formatOrderNumber(year, sequence) {
  const y = Number(year) || new Date().getFullYear();
  const seq = Math.max(1, Number(sequence) || 1);
  return `${ORDER_PREFIX}-${y}-${String(seq).padStart(3, '0')}`;
}

/**
 * Parse stored order number into prefix, year, sequence.
 */
function parseOrderNumberParts(orderNumber) {
  const raw = String(orderNumber || '').trim().toUpperCase();
  const match = raw.match(ORDER_NUMBER_PATTERN);
  if (!match) return null;
  return {
    prefix: match[1].toUpperCase(),
    year: Number(match[2]),
    sequence: Number(match[3]),
    raw,
  };
}

/**
 * Display format: legacy NEX-* shown as ORD-* (same year/sequence).
 */
function normalizeOrderNumberForDisplay(orderNumber) {
  const parts = parseOrderNumberParts(orderNumber);
  if (!parts) return String(orderNumber || '').trim().toUpperCase();
  return formatOrderNumber(parts.year, parts.sequence);
}

/**
 * Match search queries: ORD-2026-001, 2026-001, 001, NEX-2026-001 (legacy).
 */
function orderNumberMatchesSearch(orderNumber, query) {
  const q = String(query || '').trim().toLowerCase();
  if (!q) return true;

  const stored = String(orderNumber || '').trim().toLowerCase();
  const display = normalizeOrderNumberForDisplay(orderNumber).toLowerCase();

  if (stored.includes(q) || display.includes(q)) return true;

  const parts = parseOrderNumberParts(orderNumber);
  if (!parts) return false;

  const yearSeq = `${parts.year}-${String(parts.sequence).padStart(3, '0')}`;
  const yearSeqShort = `${parts.year}-${parts.sequence}`;
  const seqPadded = String(parts.sequence).padStart(3, '0');
  const seqPlain = String(parts.sequence);

  return (
    yearSeq.includes(q) ||
    yearSeqShort.includes(q) ||
    seqPadded.includes(q) ||
    seqPlain === q ||
    seqPadded === q
  );
}

/**
 * Highest sequence for a calendar year across ORD and legacy NEX numbers.
 */
async function getMaxSequenceForYear(year) {
  const y = Number(year) || new Date().getFullYear();
  const pattern = new RegExp(`^(${ORDER_PREFIX}|${LEGACY_PREFIX})-${y}-`, 'i');

  const rows = await Order.find({ order_number: { $regex: pattern } })
    .select('order_number')
    .lean();

  let maxSeq = 0;
  for (const row of rows) {
    const parts = parseOrderNumberParts(row.order_number);
    if (parts && parts.year === y) {
      maxSeq = Math.max(maxSeq, parts.sequence);
    }
  }
  return maxSeq;
}

/**
 * Generates ORD-YYYY-### order numbers; preserves sequence after legacy NEX records.
 */
async function generateOrderNumber() {
  const year = new Date().getFullYear();
  const maxSeq = await getMaxSequenceForYear(year);
  return formatOrderNumber(year, maxSeq + 1);
}

/**
 * One-time style migration: NEX-YYYY-### → ORD-YYYY-### (same sequence, unique index safe).
 */
async function migrateLegacyOrderNumbers() {
  const legacy = await Order.find({
    order_number: { $regex: /^NEX-/i },
  })
    .select('_id order_number')
    .lean();

  if (!legacy.length) return { migrated: 0 };

  let migrated = 0;
  for (const row of legacy) {
    const parts = parseOrderNumberParts(row.order_number);
    if (!parts) continue;
    const next = formatOrderNumber(parts.year, parts.sequence);
    if (next === row.order_number) continue;

    const conflict = await Order.findOne({
      order_number: next,
      _id: { $ne: row._id },
    }).select('_id');

    if (conflict) {
      console.warn(
        `[migrateLegacyOrderNumbers] skip ${row.order_number} → ${next}: already exists`
      );
      continue;
    }

    await Order.updateOne({ _id: row._id }, { $set: { order_number: next } });
    migrated += 1;
  }

  if (migrated > 0) {
    console.log(`Migrated ${migrated} order number(s) from ${LEGACY_PREFIX} to ${ORDER_PREFIX}`);
  }
  return { migrated };
}

module.exports = {
  ORDER_PREFIX,
  LEGACY_PREFIX,
  formatOrderNumber,
  parseOrderNumberParts,
  normalizeOrderNumberForDisplay,
  orderNumberMatchesSearch,
  getMaxSequenceForYear,
  generateOrderNumber,
  migrateLegacyOrderNumbers,
};
