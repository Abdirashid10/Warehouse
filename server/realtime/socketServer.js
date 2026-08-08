const { Server } = require('socket.io');
const { User } = require('../models');
const { verifyAccessToken } = require('../utils/jwt');
const { setSocketIo } = require('./notificationEmitter');

function extractToken(socket) {
  const authToken = socket.handshake.auth?.token;
  if (authToken && typeof authToken === 'string') return authToken.trim();

  const header = socket.handshake.headers?.authorization;
  if (header && typeof header === 'string' && header.startsWith('Bearer ')) {
    return header.slice(7).trim();
  }
  return null;
}

function initSocketServer(httpServer) {
  const io = new Server(httpServer, {
    cors: {
      origin: true,
      credentials: true,
    },
    path: '/socket.io',
  });

  io.use(async (socket, next) => {
    try {
      const token = extractToken(socket);
      if (!token) {
        return next(new Error('Authentication required'));
      }

      const payload = verifyAccessToken(token);
      const userId = payload.sub;
      if (!userId) {
        return next(new Error('Invalid token'));
      }

      const user = await User.findById(userId).select('_id role archived status').lean();
      if (!user) {
        return next(new Error('User not found'));
      }
      if (user.archived || user.status === 'Archived' || user.status === 'Suspended') {
        return next(new Error('Account inactive'));
      }

      socket.userId = user._id.toString();
      socket.userRole = user.role;
      return next();
    } catch {
      return next(new Error('Invalid or expired token'));
    }
  });

  io.on('connection', (socket) => {
    socket.join(`user:${socket.userId}`);
    socket.emit('socket:connected', { userId: socket.userId });
  });

  setSocketIo(io);
  return io;
}

module.exports = { initSocketServer };
