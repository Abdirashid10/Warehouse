export function getInitials(fullName, username, email) {
  const source = (fullName || username || email || 'U').trim();
  const parts = source.split(/\s+/).filter(Boolean);
  if (parts.length >= 2) {
    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
  }
  return source.slice(0, 2).toUpperCase();
}

export function readImageFileAsDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error('Failed to read image file'));
    reader.readAsDataURL(file);
  });
}

export async function validateAvatarFile(file) {
  if (!file) throw new Error('No file selected');
  const allowed = ['image/jpeg', 'image/png', 'image/webp'];
  if (!allowed.includes(file.type)) {
    throw new Error('Please upload a JPEG, PNG, or WebP image');
  }
  if (file.size > 350 * 1024) {
    throw new Error('Image must be smaller than 350KB');
  }
  return readImageFileAsDataUrl(file);
}
