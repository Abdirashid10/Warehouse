function formatProfileUser(doc) {
  if (!doc) return null;
  const row = doc.toObject ? doc.toObject() : doc;
  return {
    id: row._id?.toString(),
    username: row.username,
    email: row.email,
    fullName: row.fullName || '',
    phone: row.phone || '',
    avatar: row.avatar || '',
    role: row.role,
    status: row.status || 'Active',
    archived: Boolean(row.archived),
    lastLoginAt: row.lastLoginAt || null,
    lastActiveAt: row.lastActiveAt || null,
    createdAt: row.createdAt || null,
    forcePasswordChange: Boolean(row.forcePasswordChange),
    preferences: row.preferences || null,
  };
}

function getRolePermissions(role) {
  if (role === 'Admin') {
    return [
      'Full system administration',
      'User & role management',
      'All warehouses and inventory',
      'Reports and audit logs',
    ];
  }
  if (role === 'Supervisor') {
    return [
      'Inventory and stock movements',
      'Orders and fulfillment',
      'Warehouse management',
      'Reports access',
    ];
  }
  return [
    'View assigned inventory',
    'Receive, dispatch, and transfer stock',
    'Update task status and process orders',
  ];
}

function isEmail(value) {
  return typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
}

function validateAvatarDataUrl(avatar) {
  if (!avatar) return null;
  if (typeof avatar !== 'string') return 'Avatar must be a string';
  if (avatar.length > 512000) return 'Avatar image is too large (max ~375KB)';
  if (!avatar.startsWith('data:image/')) return 'Avatar must be a JPEG, PNG, or WebP image';
  const mime = avatar.slice(5, avatar.indexOf(';'));
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(mime)) {
    return 'Avatar must be JPEG, PNG, or WebP';
  }
  return null;
}

function validateProfileFields(body, { requireUsername = true } = {}) {
  const errors = [];
  if (body.username !== undefined) {
    const u = String(body.username || '').trim();
    if (requireUsername && u.length < 2) errors.push('Username must be at least 2 characters');
  }
  if (body.email !== undefined) {
    const em = String(body.email || '').trim().toLowerCase();
    if (!isEmail(em)) errors.push('A valid email is required');
  }
  if (body.fullName !== undefined && String(body.fullName).length > 120) {
    errors.push('Full name is too long');
  }
  if (body.phone !== undefined && String(body.phone).length > 30) {
    errors.push('Phone number is too long');
  }
  return errors;
}

module.exports = {
  formatProfileUser,
  getRolePermissions,
  validateAvatarDataUrl,
  validateProfileFields,
  isEmail,
};
