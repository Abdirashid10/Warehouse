const { getIo } = require('./notificationEmitter');

function emitInventoryChanged(payload = {}) {
  const io = getIo();
  if (!io) return;
  io.emit('inventory:changed', {
    at: new Date().toISOString(),
    ...payload,
  });
}

module.exports = { emitInventoryChanged };
