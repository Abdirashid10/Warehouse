/**
 * Expiry date tracking — derived from live dates, never stored.
 *
 * EXPIRED:       expiryDate is in the past
 * EXPIRING_SOON: within 7 days
 * EXPIRING_30D:  within 30 days
 * SAFE:          more than 30 days or no expiry set
 */

const EXPIRY_STATUSES = ['Expired', 'Expiring Soon', 'Expiring (30d)', 'Safe', 'No Expiry'];

const MS_PER_DAY = 86_400_000;

function daysUntilExpiry(expiryDate) {
  if (!expiryDate) return null;
  const exp = new Date(expiryDate);
  if (isNaN(exp.getTime())) return null;
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  const expDay = new Date(exp);
  expDay.setHours(0, 0, 0, 0);
  return Math.ceil((expDay - now) / MS_PER_DAY);
}

function getExpiryStatus(expiryDate) {
  const days = daysUntilExpiry(expiryDate);
  if (days === null) return 'No Expiry';
  if (days <= 0) return 'Expired';
  if (days <= 7) return 'Expiring Soon';
  if (days <= 30) return 'Expiring (30d)';
  return 'Safe';
}

function isExpired(expiryDate) {
  const d = daysUntilExpiry(expiryDate);
  return d !== null && d <= 0;
}

function isExpiringSoon(expiryDate) {
  const d = daysUntilExpiry(expiryDate);
  return d !== null && d > 0 && d <= 7;
}

function isExpiring30d(expiryDate) {
  const d = daysUntilExpiry(expiryDate);
  return d !== null && d > 7 && d <= 30;
}

function applyExpiryStatusToRow(row) {
  if (!row || typeof row !== 'object') return row;
  const expiryDate = row.expiry_date || row.expiryDate || null;
  const days = daysUntilExpiry(expiryDate);
  const expiry_status = getExpiryStatus(expiryDate);
  return {
    ...row,
    expiry_date: expiryDate ? new Date(expiryDate).toISOString() : null,
    days_until_expiry: days,
    expiry_status,
  };
}

function enrichInventoryRowsWithExpiry(rows) {
  if (!Array.isArray(rows)) return [];
  return rows.map(applyExpiryStatusToRow);
}

function summarizeExpiryRows(rows) {
  const enriched = enrichInventoryRowsWithExpiry(rows);
  return {
    expired: enriched.filter((r) => r.expiry_status === 'Expired').length,
    expiring_soon: enriched.filter((r) => r.expiry_status === 'Expiring Soon').length,
    expiring_30d: enriched.filter((r) => r.expiry_status === 'Expiring (30d)').length,
    safe: enriched.filter((r) => r.expiry_status === 'Safe').length,
    no_expiry: enriched.filter((r) => r.expiry_status === 'No Expiry').length,
  };
}

function validateExpiryDates(manufactureDate, expiryDate) {
  const errors = [];
  if (expiryDate) {
    const exp = new Date(expiryDate);
    if (isNaN(exp.getTime())) {
      errors.push('Invalid expiry date');
    } else if (manufactureDate) {
      const mfg = new Date(manufactureDate);
      if (!isNaN(mfg.getTime()) && exp <= mfg) {
        errors.push('Expiry date must be after manufacture date');
      }
    }
  }
  if (manufactureDate) {
    const mfg = new Date(manufactureDate);
    if (isNaN(mfg.getTime())) {
      errors.push('Invalid manufacture date');
    }
  }
  return errors.length ? errors : null;
}

module.exports = {
  EXPIRY_STATUSES,
  daysUntilExpiry,
  getExpiryStatus,
  isExpired,
  isExpiringSoon,
  isExpiring30d,
  applyExpiryStatusToRow,
  enrichInventoryRowsWithExpiry,
  summarizeExpiryRows,
  validateExpiryDates,
};
