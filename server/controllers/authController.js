const { User, ROLES } = require('../models');
const { signAccessToken } = require('../utils/jwt');
const { formatProfileUser } = require('../utils/userProfileDto');
const { notifyLogin, notifyUserLifecycle } = require('../services/notificationService');

function isEmail(value) {
  return typeof value === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
}

async function login(req, res) {
  try {
    const { email, username, password } = req.body;

    if (!password || typeof password !== 'string') {
      return res.status(400).json({ message: 'Password is required' });
    }
    let query = null;
    if (email && typeof email === 'string') {
      query = { email: email.trim().toLowerCase() };
    } else if (username && typeof username === 'string') {
      query = { username: username.trim() };
    }

    if (!query) {
      return res.status(400).json({ message: 'Email or username is required' });
    }

    const user = await User.findOne(query).select('+password');
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (user.archived || user.status === 'Archived') {
      return res.status(403).json({
        message: 'This account has been archived. Contact an administrator.',
      });
    }
    if (user.status === 'Suspended') {
      return res.status(403).json({
        message: 'This account has been suspended. Contact an administrator.',
      });
    }

    const match = await user.comparePassword(password);
    if (!match) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    user.lastLoginAt = new Date();
    user.lastActiveAt = new Date();
    await user.save();

    const token = signAccessToken({
      sub: user._id.toString(),
      role: user.role,
    });

    const profile = formatProfileUser(user);
    await notifyLogin({ user: { ...profile, id: user._id.toString() } });

    return res.json({
      token,
      user: profile,
    });
  } catch (err) {
    console.error('login error:', err.message);
    return res.status(500).json({ message: 'Login failed' });
  }
}

async function register(req, res) {
  try {
    const { username, email, password, role } = req.body;

    if (!username || typeof username !== 'string' || username.trim().length < 2) {
      return res.status(400).json({ message: 'Username must be at least 2 characters' });
    }
    if (!email || typeof email !== 'string' || !isEmail(email)) {
      return res.status(400).json({ message: 'A valid email is required' });
    }
    if (!password || typeof password !== 'string' || password.length < 8) {
      return res.status(400).json({ message: 'Password must be at least 8 characters' });
    }

    let assignedRole = 'Staff';
    if (role !== undefined && role !== null && role !== '') {
      if (!ROLES.includes(role)) {
        return res.status(400).json({ message: `Role must be one of: ${ROLES.join(', ')}` });
      }
      assignedRole = role;
    }

    const user = await User.create({
      username: username.trim(),
      email: email.trim().toLowerCase(),
      password,
      role: assignedRole,
      status: 'Active',
    });

    const token = signAccessToken({
      sub: user._id.toString(),
      role: user.role,
    });

    await notifyUserLifecycle({
      action: 'created',
      targetUser: user,
      actorId: null,
      actorName: 'System',
    });

    return res.status(201).json({
      token,
      user: formatProfileUser(user),
    });
  } catch (err) {
    if (err.code === 11000) {
      const field = Object.keys(err.keyPattern || {})[0] || 'field';
      return res.status(409).json({ message: `${field} is already registered` });
    }
    console.error('register error:', err.message);
    return res.status(500).json({ message: 'Registration failed' });
  }
}

async function bootstrapFirstAdmin(req, res) {
  try {
    const count = await User.countDocuments();
    if (count > 0) {
      return res.status(403).json({ message: 'Bootstrap is only allowed when no users exist' });
    }

    const { username, email, password } = req.body;

    if (!username || typeof username !== 'string' || username.trim().length < 2) {
      return res.status(400).json({ message: 'Username must be at least 2 characters' });
    }
    if (!email || typeof email !== 'string' || !isEmail(email)) {
      return res.status(400).json({ message: 'A valid email is required' });
    }
    if (!password || typeof password !== 'string' || password.length < 8) {
      return res.status(400).json({ message: 'Password must be at least 8 characters' });
    }

    const user = await User.create({
      username: username.trim(),
      email: email.trim().toLowerCase(),
      password,
      role: 'Admin',
      status: 'Active',
    });

    const token = signAccessToken({
      sub: user._id.toString(),
      role: user.role,
    });

    return res.status(201).json({
      token,
      user: formatProfileUser(user),
    });
  } catch (err) {
    if (err.code === 11000) {
      const field = Object.keys(err.keyPattern || {})[0] || 'field';
      return res.status(409).json({ message: `${field} is already registered` });
    }
    console.error('bootstrap error:', err.message);
    return res.status(500).json({ message: 'Bootstrap failed' });
  }
}

async function getBootstrapStatus(_req, res) {
  try {
    const count = await User.countDocuments();
    return res.json({ canBootstrap: count === 0 });
  } catch (err) {
    console.error('getBootstrapStatus error:', err.message);
    return res.status(500).json({ message: 'Failed to read bootstrap status' });
  }
}

module.exports = { login, register, bootstrapFirstAdmin, getBootstrapStatus };
