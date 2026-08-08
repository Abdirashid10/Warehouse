const mongoose = require('mongoose');
const { User, Warehouse } = require('../models');
const { verifyAccessToken } = require('../utils/jwt');

/**
 * Verifies Bearer JWT, loads user, attaches req.user.
 */
async function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Access token required' });
  }

  const token = authHeader.slice(7).trim();
  if (!token) {
    return res.status(401).json({ message: 'Access token required' });
  }

  try {
    const payload = verifyAccessToken(token);
    const userId = String(payload.sub || payload.id || '').trim();
    if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(401).json({ message: 'Invalid token payload' });
    }

    const user = await User.findById(userId).select(
      '_id username email role archived status forcePasswordChange assignedWarehouseIds'
    );
    if (!user) {
      return res.status(401).json({ message: 'User no longer exists' });
    }

    if (user.archived || user.status === 'Archived') {
      return res.status(403).json({ message: 'Account archived. Access denied.' });
    }
    if (user.status === 'Suspended') {
      return res.status(403).json({ message: 'Account suspended. Access denied.' });
    }

    await User.findByIdAndUpdate(user._id, { $set: { lastActiveAt: new Date() } });

    let assignedWarehouseIds = (user.assignedWarehouseIds || []).map((id) => id.toString());
    if (
      (user.role === 'Staff' || user.role === 'Supervisor') &&
      assignedWarehouseIds.length === 0
    ) {
      const warehouseQuery =
        user.role === 'Staff'
          ? { assignedStaffIds: user._id }
          : { $or: [{ assignedStaffIds: user._id }, { createdBy: user._id }] };
      const linked = await Warehouse.find(warehouseQuery).select('_id').lean();
      if (linked.length) {
        assignedWarehouseIds = linked.map((w) => w._id.toString());
        await User.updateOne(
          { _id: user._id },
          { $addToSet: { assignedWarehouseIds: { $each: linked.map((w) => w._id) } } }
        );
      }
    }

    req.user = {
      id: user._id.toString(),
      username: user.username,
      email: user.email,
      role: user.role,
      archived: Boolean(user.archived),
      status: user.status || 'Active',
      forcePasswordChange: Boolean(user.forcePasswordChange),
      assignedWarehouseIds,
    };
    return next();
  } catch {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

/**
 * Restricts route to roles listed in `allowedRoles`. Use after authenticate.
 * @param {string[]} allowedRoles e.g. ['Admin', 'Supervisor']
 */
function checkRole(allowedRoles) {
  if (!Array.isArray(allowedRoles) || allowedRoles.length === 0) {
    throw new Error('checkRole() requires a non-empty array of role names');
  }

  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
    }
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Insufficient permissions for this action' });
    }
    return next();
  };
}

/**
 * Variadic helper: authorize('Admin', 'Supervisor') — same as checkRole([...]).
 * @param {...string} allowedRoles
 */
function authorize(...allowedRoles) {
  return checkRole(allowedRoles);
}

module.exports = { authenticate, checkRole, authorize };
