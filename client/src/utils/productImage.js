import { api } from '../api/client';

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_BYTES = 2 * 1024 * 1024;

export function resolveProductImageUrl(url) {
  if (!url) return null;
  const value = String(url).trim();
  if (!value) return null;

  const lower = value.toLowerCase();
  if (lower.startsWith('file://') || lower.startsWith('file:\\') || lower.startsWith('file:/')) {
    return null;
  }
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return value;
  }
  if (value.startsWith('/uploads/')) {
    return value;
  }
  if (value.startsWith('blob:')) {
    return value;
  }
  return null;
}

export function validateProductImageFile(file) {
  if (!file) throw new Error('No file selected');
  if (!ALLOWED_TYPES.includes(file.type)) {
    throw new Error('Please upload a JPEG, PNG, or WebP image');
  }
  if (file.size > MAX_BYTES) {
    throw new Error('Image must be smaller than 2MB');
  }
  return file;
}

export async function uploadProductImageFile(file) {
  const valid = validateProductImageFile(file);
  const formData = new FormData();
  formData.append('image', valid);
  const { data } = await api.post('/products/upload-image', formData, {
    headers: { 'Content-Type': 'multipart/form-data' },
  });
  return data.image_url;
}
