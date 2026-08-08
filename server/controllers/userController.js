const mongoose = require('mongoose');
const { User, ROLES, USER_STATUSES } = require('../models');
const { logAudit } = require('../utils/activityLogger');
const { notifyUserLifecycle, notifyUserStatusChanged } = require('../services/notificationService');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

async function countActiveAdmins() {
  return User.countDocuments({ role: 'Admin', archived: { $ne: true } });
}

/**
 * List all users (no passwords). Admin only.
 */
async function listUsers(_req, res) {
  try {
    const users = await User.find()
      .select(
        'username email role archived archivedAt status suspendedAt lastLoginAt lastActiveAt forcePasswordChange createdAt updatedAt'
      )
      .sort({ status: 1, username: 1 })
      .lean();

    return res.json({ users });
  } catch (err) {
    console.error('listUsers error:', err.message);
    return res.status(500).json({ message: 'Failed to load users' });
  }
}

/**
 * Update username, email, role, and/or password. Admin only.
 */
async function updateUser(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }

    const target = await User.findById(id);
    if (!target) {
      return res.status(404).json({ message: 'User not found' });
    }

    const { username, email, role, password, forcePasswordChange } = req.body;

    if (role !== undefined && role !== null && role !== '') {
      if (!ROLES.includes(role)) {
        return res.status(400).json({ message: `Role must be one of: ${ROLES.join(', ')}` });
      }
      if (target.role === 'Admin' && role !== 'Admin') {
        const admins = await countActiveAdmins();
        if (admins <= 1) {
          return res.status(400).json({ message: 'Cannot change role of the last active Admin' });
        }
      }
      const previousRole = target.role;
      target.role = role;
      await logAudit(req, {
        actorId: req.user.id,
        actorRole: req.user.role,
        targetUserId: target._id,
        action: 'Update',
        module: 'User Management',
        entityType: 'user',
        entityId: target._id.toString(),
        entityLabel: target.username,
        beforeValue: { role: previousRole },
        afterValue: { role },
        details: `Role changed to ${role}`,
      });
    }

    if (username !== undefined && username !== null) {
      const u = String(username).trim();
      if (u.length < 2) {
        return res.status(400).json({ message: 'Username must be at least 2 characters' });
      }
      target.username = u;
    }

    if (email !== undefined && email !== null) {
      const em = String(email).trim().toLowerCase();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(em)) {
        return res.status(400).json({ message: 'Invalid email' });
      }
      target.email = em;
    }

    if (password !== undefined && password !== null && password !== '') {
      if (typeof password !== 'string' || password.length < 8) {
        return res.status(400).json({ message: 'Password must be at least 8 characters' });
      }
      target.password = password;
    }
    if (forcePasswordChange !== undefined) {
      target.forcePasswordChange = Boolean(forcePasswordChange);
    }

    await target.save();
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      targetUserId: target._id,
      action: 'Update',
      module: 'User Management',
      entityType: 'user',
      entityId: target._id.toString(),
      entityLabel: target.username,
      details: 'Profile/security settings updated',
    });

    const fresh = await User.findById(id)
      .select(
        'username email role archived archivedAt status suspendedAt lastLoginAt lastActiveAt forcePasswordChange createdAt updatedAt'
      )
      .lean();

    return res.json({ user: fresh });
  } catch (err) {
    if (err.code === 11000) {
      const field = Object.keys(err.keyPattern || {})[0] || 'field';
      return res.status(409).json({ message: `${field} is already in use` });
    }
    if (err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    console.error('updateUser error:', err.message);
    return res.status(500).json({ message: 'Failed to update user' });
  }
}

/**
 * Hard delete user. Admin only. Cannot delete self or last active Admin.
 */
async function deleteUser(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }

    if (String(id) === req.user.id) {
      return res.status(400).json({ message: 'You cannot delete your own account' });
    }

    const target = await User.findById(id);
    if (!target) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (target.role === 'Admin' && !target.archived) {
      const admins = await countActiveAdmins();
      if (admins <= 1) {
        return res.status(400).json({ message: 'Cannot delete the last active Admin' });
      }
    }

    await User.findByIdAndDelete(id);
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      targetUserId: target._id,
      action: 'Disable',
      module: 'User Management',
      entityType: 'user',
      entityId: target._id.toString(),
      entityLabel: target.username,
      beforeValue: { status: target.status, role: target.role },
      details: `${target.username} (${target.email}) removed`,
    });
    await notifyUserLifecycle({
      action: 'deleted',
      targetUser: target,
      actorId: req.user.id,
      actorName: req.user.username,
    });
    return res.json({ message: 'User deleted' });
  } catch (err) {
    console.error('deleteUser error:', err.message);
    return res.status(500).json({ message: 'Failed to delete user' });
  }
}

/**
 * Promote Staff → Supervisor. Admin only.
 */
async function promoteUser(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }

    const target = await User.findById(id);
    if (!target) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (target.archived) {
      return res.status(400).json({ message: 'Cannot promote an archived user' });
    }

    if (target.role !== 'Staff') {
      return res.status(400).json({
        message: 'Only Staff accounts can be promoted to Supervisor',
      });
    }

    target.role = 'Supervisor';
    await target.save();
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      targetUserId: target._id,
      action: 'Update',
      module: 'User Management',
      entityType: 'user',
      entityId: target._id.toString(),
      entityLabel: target.username,
      beforeValue: { role: 'Staff' },
      afterValue: { role: 'Supervisor' },
      details: 'Staff promoted to Supervisor',
    });

    const fresh = await User.findById(id)
      .select(
        'username email role archived archivedAt status suspendedAt lastLoginAt lastActiveAt forcePasswordChange createdAt updatedAt'
      )
      .lean();

    return res.json({ user: fresh });
  } catch (err) {
    console.error('promoteUser error:', err.message);
    return res.status(500).json({ message: 'Failed to promote user' });
  }
}

/**
 * Archive or restore a user. Archived users cannot sign in or use the API.
 */
async function setArchived(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }

    const { archived } = req.body;
    if (typeof archived !== 'boolean') {
      return res.status(400).json({ message: 'Body must include archived: true or false' });
    }

    const target = await User.findById(id);
    if (!target) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (String(id) === req.user.id && archived) {
      return res.status(400).json({ message: 'You cannot archive your own account' });
    }

    if (target.role === 'Admin' && !target.archived && archived) {
      const admins = await countActiveAdmins();
      if (admins <= 1) {
        return res.status(400).json({ message: 'Cannot archive the last active Admin' });
      }
    }

    target.archived = archived;
    target.archivedAt = archived ? new Date() : null;
    target.status = archived ? 'Archived' : 'Active';
    if (!archived) target.suspendedAt = null;
    await target.save();
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      targetUserId: target._id,
      action: archived ? 'Disable' : 'Update',
      module: 'User Management',
      entityType: 'user',
      entityId: target._id.toString(),
      entityLabel: target.username,
      beforeValue: { archived: !archived },
      afterValue: { archived },
      details: archived ? 'User archived and disabled from login' : 'User restored to active status',
    });
    if (archived) {
      await notifyUserLifecycle({
        action: 'archived',
        targetUser: target,
        actorId: req.user.id,
        actorName: req.user.username,
      });
    }

    const fresh = await User.findById(id)
      .select(
        'username email role archived archivedAt status suspendedAt lastLoginAt lastActiveAt forcePasswordChange createdAt updatedAt'
      )
      .lean();

    return res.json({ user: fresh });
  } catch (err) {
    console.error('setArchived error:', err.message);
    return res.status(500).json({ message: 'Failed to update archive status' });
  }
}

async function setStatus(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }
    const { status } = req.body;
    if (!USER_STATUSES.includes(status)) {
      return res.status(400).json({ message: `status must be one of: ${USER_STATUSES.join(', ')}` });
    }

    const target = await User.findById(id);
    if (!target) return res.status(404).json({ message: 'User not found' });
    if (String(id) === req.user.id && status !== 'Active') {
      return res.status(400).json({ message: 'You cannot disable your own account' });
    }
    if (target.role === 'Admin' && status !== 'Active') {
      const admins = await countActiveAdmins();
      if (admins <= 1) {
        return res.status(400).json({ message: 'Cannot disable the last active Admin' });
      }
    }

    const previousStatus = target.status;
    target.status = status;
    target.archived = status === 'Archived';
    target.archivedAt = status === 'Archived' ? new Date() : null;
    target.suspendedAt = status === 'Suspended' ? new Date() : null;
    await target.save();
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      targetUserId: target._id,
      action: 'Status Change',
      module: 'User Management',
      entityType: 'user',
      entityId: target._id.toString(),
      entityLabel: target.username,
      beforeValue: { status: previousStatus },
      afterValue: { status },
      details: `Status changed to ${status}`,
    });
    if (status === 'Suspended') {
      await notifyUserLifecycle({
        action: 'suspended',
        targetUser: target,
        actorId: req.user.id,
        actorName: req.user.username,
      });
    } else if (status === 'Archived') {
      await notifyUserLifecycle({
        action: 'archived',
        targetUser: target,
        actorId: req.user.id,
        actorName: req.user.username,
      });
    } else if (previousStatus !== status) {
      await notifyUserStatusChanged({
        targetUser: target,
        previousStatus,
        newStatus: status,
        actorId: req.user.id,
        actorName: req.user.username,
      });
    }

    const fresh = await User.findById(id)
      .select(
        'username email role archived archivedAt status suspendedAt lastLoginAt lastActiveAt forcePasswordChange createdAt updatedAt'
      )
      .lean();
    return res.json({ user: fresh });
  } catch (err) {
    console.error('setStatus error:', err.message);
    return res.status(500).json({ message: 'Failed to update user status' });
  }
}

function generateTempPassword(length = 12) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%';
  let out = '';
  for (let i = 0; i < length; i += 1) {
    out += chars[Math.floor(Math.random() * chars.length)];
  }
  return out;
}

async function resetUserPassword(req, res) {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) {
      return res.status(400).json({ message: 'Invalid user id' });
    }
    if (String(id) === req.user.id) {
      return res.status(400).json({ message: 'Use profile flow to reset your own password' });
    }
    const target = await User.findById(id);
    if (!target) return res.status(404).json({ message: 'User not found' });

    const temporaryPassword = generateTempPassword(12);
    target.password = temporaryPassword;
    target.forcePasswordChange = true;
    await target.save();
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      targetUserId: target._id,
      action: 'Update',
      module: 'User Management',
      entityType: 'user',
      entityId: target._id.toString(),
      entityLabel: target.username,
      details: 'Temporary password generated and force change enabled',
    });

    return res.json({
      message: 'Password reset completed',
      temporaryPassword,
      forcePasswordChange: true,
    });
  } catch (err) {
    console.error('resetUserPassword error:', err.message);
    return res.status(500).json({ message: 'Failed to reset password' });
  }
}

module.exports = {
  listUsers,
  updateUser,
  deleteUser,
  promoteUser,
  setArchived,
  setStatus,
  resetUserPassword,
};
