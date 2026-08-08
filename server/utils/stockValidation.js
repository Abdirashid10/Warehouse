const { Inventory } = require('../models');
const { validateConditionRequired, normalizeCondition } = require('../constants/inventoryConditions');

function formatInsufficientStockMessage(availableQuantity) {
  const available = Number(availableQuantity) || 0;
  return `Insufficient stock. Available quantity: ${available}`;
}

function insufficientStockError(availableQuantity) {
  return Object.assign(new Error(formatInsufficientStockMessage(availableQuantity)), {
    status: 400,
    code: 'INSUFFICIENT_STOCK',
    availableQuantity: Number(availableQuantity) || 0,
  });
}

function validatePositiveIntegerQuantity(quantity, label = 'Quantity') {
  const qty = Number(quantity);
  if (!Number.isFinite(qty) || qty <= 0 || !Number.isInteger(qty)) {
    throw Object.assign(new Error(`${label} must be a positive integer`), { status: 400 });
  }
  return qty;
}

async function getConditionQtyAtWarehouse(productId, warehouseId, condition, session = null) {
  const filter = {
    productId,
    warehouseId,
    condition: normalizeCondition(condition),
  };
  let query = Inventory.find(filter);
  if (session) query = query.session(session);
  const lines = await query.lean();
  return lines.reduce((sum, line) => sum + (line.quantity || 0), 0);
}

async function assertSufficientConditionStock({
  productId,
  warehouseId,
  condition,
  quantity,
  session = null,
}) {
  const qty = validatePositiveIntegerQuantity(quantity);
  const available = await getConditionQtyAtWarehouse(productId, warehouseId, condition, session);

  if (available <= 0) {
    throw Object.assign(
      new Error('No inventory record found for this product at the source warehouse'),
      { status: 400, code: 'NO_INVENTORY' }
    );
  }

  if (qty > available) {
    throw insufficientStockError(available);
  }

  return { quantity: qty, availableQuantity: available };
}

async function validateTransferRequest({
  productId,
  fromWarehouseId,
  toWarehouseId,
  quantity,
  condition,
  session = null,
}) {
  const qty = validatePositiveIntegerQuantity(quantity);

  if (!fromWarehouseId || !toWarehouseId) {
    throw Object.assign(new Error('fromWarehouseId and toWarehouseId are required for transfers'), {
      status: 400,
    });
  }

  if (String(fromWarehouseId) === String(toWarehouseId)) {
    throw Object.assign(new Error('Source and destination warehouses must be different'), {
      status: 400,
    });
  }

  const lineCondition = validateConditionRequired(condition);
  const result = await assertSufficientConditionStock({
    productId,
    warehouseId: fromWarehouseId,
    condition: lineCondition,
    quantity: qty,
    session,
  });

  return {
    quantity: qty,
    condition: lineCondition,
    availableQuantity: result.availableQuantity,
  };
}

module.exports = {
  formatInsufficientStockMessage,
  insufficientStockError,
  validatePositiveIntegerQuantity,
  getConditionQtyAtWarehouse,
  assertSufficientConditionStock,
  validateTransferRequest,
};
