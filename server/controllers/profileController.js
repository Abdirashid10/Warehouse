const { User, UserActivityLog, Movement, Warehouse } = require('../models');
const { hasGlobalWarehouseAccess } = require('../utils/warehouseAccess');
const { logActivity } = require('../utils/activityLogger');
const {
  formatProfileUser,
  getRolePermissions,
  validateAvatarDataUrl,
  validateProfileFields,
} = require('../utils/userProfileDto');

const DEFAULT_APPEARANCE = {
  theme: 'system',
  accent: 'sky',
  sidebarStyle: 'default',
  animations: true,
  compactTables: true,
  breadcrumbs: true,
  sidebarCollapsed: false,
};

async function loadUserOr404(userId) {
  return User.findById(userId).select(
    'username email fullName phone avatar role status archived lastLoginAt lastActiveAt createdAt forcePasswordChange preferences assignedWarehouseIds'
  );
}

async function formatAssignedWarehousesForProfile(user) {
  if (hasGlobalWarehouseAccess(user.role)) {
    return { scope: 'all', warehouses: [] };
  }
  const ids = user.assignedWarehouseIds || [];
  if (!ids.length) {
    return { scope: 'assigned', warehouses: [] };
  }
  const rows = await Warehouse.find({ _id: { $in: ids } }).select('name location').sort({ name: 1 }).lean();
  return {
    scope: 'assigned',
    warehouses: rows.map((w) => ({
      id: w._id.toString(),
      name: w.name,
      location: w.location,
    })),
  };
}

async function getMyProfile(req, res) {
  try {
    const user = await loadUserOr404(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const [activities, recentMovements] = await Promise.all([
      UserActivityLog.find({ actorId: user._id })
        .sort({ createdAt: -1 })
        .limit(12)
        .lean(),
      Movement.find({ $or: [{ userId: user._id }, { createdBy: user._id }] })
        .sort({ createdAt: -1 })
        .limit(6)
        .populate('productId', 'sku name')
        .populate('warehouseId', 'name')
        .lean(),
    ]);

    const assignedWarehouses = await formatAssignedWarehousesForProfile(user);

    return res.json({
      profile: formatProfileUser(user),
      permissions: getRolePermissions(user.role),
      assigned_warehouses: assignedWarehouses,
      assignedWarehouse:
        assignedWarehouses.warehouses?.length === 1
          ? assignedWarehouses.warehouses[0].name
          : assignedWarehouses.warehouses?.length > 1
            ? `${assignedWarehouses.warehouses.length} warehouses`
            : null,
      activity: activities.map((log) => ({
        id: log._id.toString(),
        action: log.action,
        module: log.module,
        details: log.details || '',
        createdAt: log.createdAt,
      })),
      recentMovements: recentMovements.map((m) => ({
        id: m._id.toString(),
        type: m.type,
        quantity: m.quantity,
        product: m.productId ? { sku: m.productId.sku, name: m.productId.name } : null,
        warehouse: m.warehouseId ? { name: m.warehouseId.name } : null,
        createdAt: m.createdAt,
      })),
      loginActivity: user.lastLoginAt
        ? [{ at: user.lastLoginAt, label: 'Last sign-in' }]
        : [],
    });
  } catch (err) {
    console.error('getMyProfile error:', err.message);
    return res.status(500).json({ message: 'Failed to load profile' });
  }
}

async function updateMyProfile(req, res) {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const { fullName, username, email, phone } = req.body;
    const errors = validateProfileFields({ username, email, fullName, phone });
    if (errors.length) return res.status(400).json({ message: errors[0] });

    if (fullName !== undefined) user.fullName = String(fullName).trim();
    if (phone !== undefined) user.phone = String(phone).trim();

    if (username !== undefined) {
      const u = String(username).trim();
      if (u.length < 2) return res.status(400).json({ message: 'Username must be at least 2 characters' });
      user.username = u;
    }

    if (email !== undefined) {
      const em = String(email).trim().toLowerCase();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(em)) {
        return res.status(400).json({ message: 'Invalid email address' });
      }
      user.email = em;
    }

    await user.save();

    await logActivity({
      actorId: user._id,
      action: 'Updated profile',
      module: 'Profile',
      details: 'Personal information updated',
    });

    const fresh = await loadUserOr404(user._id);
    return res.json({ profile: formatProfileUser(fresh) });
  } catch (err) {
    if (err.code === 11000) {
      const field = Object.keys(err.keyPattern || {})[0] || 'field';
      return res.status(409).json({ message: `${field} is already in use` });
    }
    console.error('updateMyProfile error:', err.message);
    return res.status(500).json({ message: 'Failed to update profile' });
  }
}

async function updateMyAvatar(req, res) {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const { avatar } = req.body;
    if (avatar === null || avatar === '') {
      user.avatar = '';
    } else {
      const avatarError = validateAvatarDataUrl(avatar);
      if (avatarError) return res.status(400).json({ message: avatarError });
      user.avatar = avatar;
    }

    await user.save();

    await logActivity({
      actorId: user._id,
      action: avatar ? 'Updated profile photo' : 'Removed profile photo',
      module: 'Profile',
      details: avatar ? 'Avatar image updated' : 'Avatar reset to initials',
    });

    return res.json({ profile: formatProfileUser(user), avatar: user.avatar });
  } catch (err) {
    console.error('updateMyAvatar error:', err.message);
    return res.status(500).json({ message: 'Failed to update avatar' });
  }
}

async function changeMyPassword(req, res) {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Current and new password are required' });
    }
    if (typeof newPassword !== 'string' || newPassword.length < 8) {
      return res.status(400).json({ message: 'New password must be at least 8 characters' });
    }

    const user = await User.findById(req.user.id).select('+password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    const match = await user.comparePassword(currentPassword);
    if (!match) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }

    user.password = newPassword;
    user.forcePasswordChange = false;
    await user.save();

    await logActivity({
      actorId: user._id,
      action: 'Changed password',
      module: 'Profile',
      details: 'Password updated from profile',
    });

    return res.json({ message: 'Password updated successfully' });
  } catch (err) {
    console.error('changeMyPassword error:', err.message);
    return res.status(500).json({ message: 'Failed to change password' });
  }
}

async function updateMyPreferences(req, res) {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const incoming = req.body?.preferences || req.body;
    if (!incoming || typeof incoming !== 'object') {
      return res.status(400).json({ message: 'preferences object is required' });
    }

    const merged = { ...DEFAULT_APPEARANCE, ...(user.preferences || {}), ...incoming };
    user.preferences = merged;
    await user.save();

    return res.json({ preferences: user.preferences, profile: formatProfileUser(user) });
  } catch (err) {
    console.error('updateMyPreferences error:', err.message);
    return res.status(500).json({ message: 'Failed to save preferences' });
  }
}

module.exports = {
  getMyProfile,
  updateMyProfile,
  updateMyAvatar,
  changeMyPassword,
  updateMyPreferences,
};
