const path = require('path');
const fs = require('fs');

const UPLOAD_DIR = path.join(__dirname, '..', 'uploads', 'products');
const PUBLIC_PREFIX = '/uploads/products';

const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp']);
const MAX_BYTES = 2 * 1024 * 1024;

function ensureUploadDir() {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

function isAllowedMime(mime) {
  return ALLOWED_MIME.has(mime);
}

/**
 * Reject local file paths and unsafe values. Only allow http(s) URLs or /uploads/products paths.
 */
function sanitizeImageUrl(url) {
  if (url == null || url === '') return '';
  const value = String(url).trim();
  if (!value) return '';

  const lower = value.toLowerCase();
  if (lower.startsWith('file://') || lower.startsWith('file:\\') || lower.startsWith('file:/')) {
    return '';
  }
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return value;
  }
  if (value.startsWith(`${PUBLIC_PREFIX}/`)) {
    const filename = path.basename(value);
    if (!filename || filename.includes('..')) return '';
    return `${PUBLIC_PREFIX}/${filename}`;
  }
  return '';
}

function resolveDiskPath(imageUrl) {
  const safe = sanitizeImageUrl(imageUrl);
  if (!safe.startsWith(`${PUBLIC_PREFIX}/`)) return null;
  const filename = path.basename(safe);
  return path.join(UPLOAD_DIR, filename);
}

function deleteProductImageFile(imageUrl) {
  const diskPath = resolveDiskPath(imageUrl);
  if (!diskPath || !fs.existsSync(diskPath)) return;
  try {
    fs.unlinkSync(diskPath);
  } catch (_err) {
    /* ignore missing file */
  }
}

function publicUrlFromFilename(filename) {
  return `${PUBLIC_PREFIX}/${filename}`;
}

module.exports = {
  UPLOAD_DIR,
  PUBLIC_PREFIX,
  MAX_BYTES,
  ALLOWED_MIME,
  ensureUploadDir,
  isAllowedMime,
  sanitizeImageUrl,
  deleteProductImageFile,
  publicUrlFromFilename,
};
