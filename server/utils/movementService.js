const { Product, Warehouse, Inventory, Movement } = require('../models');
const { runInventoryOperation } = require('./inventoryTransaction');
const { formatTransferReason } = require('./transferReason');
const {
  CONDITION_AVAILABLE,
  normalizeCondition,
  validateConditionRequired,
  assertOutboundAllowed,
} = require('../constants/inventoryConditions');
const {
  insufficientStockError,
  validatePositiveIntegerQuantity,
  getConditionQtyAtWarehouse,
  validateTransferRequest,
} = require('./stockValidation');

const transferQueues = new Map();

function transferLockKey(productId, fromWarehouseId, toWarehouseId, userId) {
  return `${productId}:${fromWarehouseId}:${toWarehouseId}:${userId}`;
}

async function withTransferLock(key, fn) {
  const previous = transferQueues.get(key) || Promise.resolve();
  let release;
  const gate = new Promise((resolve) => {
    release = resolve;
  });
  transferQueues.set(
    key,
    previous.finally(() => gate)
  );
  await previous;
  try {
    return await fn();
  } finally {
    release();
    if (transferQueues.get(key) === gate) {
      transferQueues.delete(key);
    }
  }
}

async function deductConditionQuantity({
  productId,
  warehouseId,
  condition,
  quantity,
  session = null,
  sessionOpt = {},
}) {
  let remaining = validatePositiveIntegerQuantity(quantity);
  const lineCondition = normalizeCondition(condition);
  const baseFilter = { productId, warehouseId, condition: lineCondition };

  while (remaining > 0) {
    let lineQuery = Inventory.findOne({ ...baseFilter, quantity: { $gt: 0 } }).sort({
      quantity: -1,
    });
    if (session) lineQuery = lineQuery.session(session);
    const line = await lineQuery.lean();
    if (!line) break;

    const deduct = Math.min(remaining, line.quantity);
    const updated = await Inventory.findOneAndUpdate(
      { _id: line._id, quantity: { $gte: deduct } },
      { $inc: { quantity: -deduct } },
      { ...sessionOpt, new: true }
    );
    if (!updated) continue;
    remaining -= deduct;
  }

  if (remaining > 0) {
    const available = await getConditionQtyAtWarehouse(
      productId,
      warehouseId,
      lineCondition,
      session
    );
    throw insufficientStockError(available);
  }
}

async function getTotalQtyAtWarehouse(productId, warehouseId, session) {
  const filter = { productId, warehouseId };
  let q = Inventory.find(filter);
  if (session) q = q.session(session);
  const lines = await q.lean();
  return lines.reduce((sum, line) => sum + (line.quantity || 0), 0);
}

async function assertSufficientStock({ productId, warehouseId, quantity, session }) {
  const qty = validatePositiveIntegerQuantity(quantity);
  const total = await getTotalQtyAtWarehouse(productId, warehouseId, session);
  if (qty > total) {
    throw insufficientStockError(total);
  }
}

function inventoryKey(productId, warehouseId, condition) {
  return {
    productId,
    warehouseId,
    condition: normalizeCondition(condition),
  };
}

/**
 * Records a stock movement and updates inventory (per product + warehouse + condition).
 * INBOUND increases stock; OUTBOUND decreases (blocked if insufficient or non-shippable condition).
 * ADJUSTMENT sets stock to targetQuantity for the given condition line.
 */
async function recordMovement({
  productId,
  warehouseId,
  userId,
  type,
  quantity,
  targetQuantity,
  reason = '',
  binLocation = '',
  condition,
  source_location = '',
  destination_location = '',
  batchNumber = '',
  manufactureDate = null,
  expiryDate = null,
}) {
  const lineCondition = validateConditionRequired(
    condition != null ? condition : CONDITION_AVAILABLE
  );

  const qty = validatePositiveIntegerQuantity(quantity);

  if (type === 'OUTBOUND') {
    assertOutboundAllowed(lineCondition);
  }

  const run = async (session) => {
    let productQ = Product.findById(productId);
    let whQ = Warehouse.findById(warehouseId);
    if (session) {
      productQ = productQ.session(session);
      whQ = whQ.session(session);
    }

    const product = await productQ;
    const wh = await whQ;
    if (!product) {
      throw Object.assign(new Error('Product not found'), { status: 404 });
    }
    if (!wh) {
      throw Object.assign(new Error('Warehouse not found'), { status: 404 });
    }

    const sessionOpt = session ? { session } : {};
    const key = inventoryKey(productId, warehouseId, lineCondition);
    let movementQty = qty;
    let delta;

    if (type === 'OUTBOUND') {
      await assertSufficientStock({ productId, warehouseId, quantity: qty, session });

      let invQ = Inventory.findOne(key);
      if (session) invQ = invQ.session(session);
      const line = await invQ;
      const lineQty = line?.quantity ?? 0;

      if (qty > lineQty) {
        throw insufficientStockError(lineQty);
      }

      const updated = await Inventory.findOneAndUpdate(
        { ...key, quantity: { $gte: qty } },
        { $inc: { quantity: -qty } },
        { ...sessionOpt, new: true }
      );
      if (!updated) {
        throw insufficientStockError(lineQty);
      }
      delta = -qty;
    } else if (type === 'INBOUND' || type === 'RETURN') {
      const expirySet = {};
      if (batchNumber) expirySet.batchNumber = String(batchNumber).trim();
      if (manufactureDate) expirySet.manufactureDate = new Date(manufactureDate);
      if (expiryDate) expirySet.expiryDate = new Date(expiryDate);

      await Inventory.findOneAndUpdate(
        key,
        {
          $inc: { quantity: qty },
          ...(Object.keys(expirySet).length ? { $set: expirySet } : {}),
          $setOnInsert: {
            productId,
            warehouseId,
            condition: lineCondition,
            binLocation: binLocation != null ? String(binLocation).trim() : '',
            createdBy: userId,
          },
        },
        { ...sessionOpt, upsert: true, new: true, runValidators: true }
      );
      delta = qty;
    } else if (type === 'ADJUSTMENT') {
      const target =
        targetQuantity != null && targetQuantity !== ''
          ? Number(targetQuantity)
          : qty;
      if (!Number.isFinite(target) || target < 0 || !Number.isInteger(target)) {
        throw Object.assign(
          new Error('targetQuantity must be a non-negative integer for adjustments'),
          { status: 400 }
        );
      }

      let invQ = Inventory.findOne(key);
      if (session) invQ = invQ.session(session);
      const line = await invQ;
      const current = line?.quantity ?? 0;
      delta = target - current;

      if (delta === 0) {
        throw Object.assign(
          new Error('Current stock already matches the target quantity'),
          { status: 400 }
        );
      }

      movementQty = Math.abs(delta);

      await Inventory.findOneAndUpdate(
        key,
        {
          $set: { quantity: target },
          $setOnInsert: {
            productId,
            warehouseId,
            condition: lineCondition,
            binLocation: binLocation != null ? String(binLocation).trim() : '',
            createdBy: userId,
          },
        },
        { ...sessionOpt, upsert: true, new: true, runValidators: true }
      );
    } else {
      throw Object.assign(new Error(`Unsupported movement type: ${type}`), { status: 400 });
    }

    const [movement] = await Movement.create(
      [
        {
          productId,
          warehouseId,
          userId,
          createdBy: userId,
          type,
          quantity: movementQty,
          delta,
          reason: reason != null ? String(reason).trim() : '',
          source_location: String(source_location || '').trim(),
          destination_location: String(destination_location || '').trim(),
          timestamp: new Date(),
        },
      ],
      sessionOpt
    );
    return movement;
  };

  return runInventoryOperation(run);
}

/**
 * Moves stock from one warehouse to another (same condition at source and destination).
 */
async function recordTransfer({
  productId,
  fromWarehouseId,
  toWarehouseId,
  userId,
  quantity,
  reason = '',
  condition,
  source_location = '',
  destination_location = '',
}) {
  const transferCondition = validateConditionRequired(
    condition != null ? condition : CONDITION_AVAILABLE
  );

  const qty = validatePositiveIntegerQuantity(quantity);

  if (String(fromWarehouseId) === String(toWarehouseId)) {
    throw Object.assign(
      new Error('Source and destination warehouses must be different'),
      { status: 400 }
    );
  }

  const run = async (session) => {
    const DUPLICATE_TRANSFER_WINDOW_MS = 5000;
    let duplicateQuery = Movement.findOne({
      type: 'TRANSFER',
      productId,
      warehouseId: fromWarehouseId,
      toWarehouseId,
      quantity: qty,
      createdBy: userId,
      createdAt: { $gte: new Date(Date.now() - DUPLICATE_TRANSFER_WINDOW_MS) },
    }).sort({ createdAt: -1 });
    if (session) duplicateQuery = duplicateQuery.session(session);
    const recentDuplicate = await duplicateQuery;
    if (recentDuplicate) {
      return { movement: recentDuplicate, isDuplicate: true };
    }

    let productQ = Product.findById(productId);
    let fromQ = Warehouse.findById(fromWarehouseId);
    let toQ = Warehouse.findById(toWarehouseId);
    if (session) {
      productQ = productQ.session(session);
      fromQ = fromQ.session(session);
      toQ = toQ.session(session);
    }

    const [product, fromWh, toWh] = await Promise.all([productQ, fromQ, toQ]);
    if (!product) {
      throw Object.assign(new Error('Product not found'), { status: 404 });
    }
    if (!fromWh) {
      throw Object.assign(new Error('Source warehouse not found'), { status: 404 });
    }
    if (!toWh) {
      throw Object.assign(new Error('Destination warehouse not found'), { status: 404 });
    }

    await validateTransferRequest({
      productId,
      fromWarehouseId,
      toWarehouseId,
      quantity: qty,
      condition: transferCondition,
      session,
    });

    const sessionOpt = session ? { session } : {};

    await deductConditionQuantity({
      productId,
      warehouseId: fromWarehouseId,
      condition: transferCondition,
      quantity: qty,
      session,
      sessionOpt,
    });

    const destKey = inventoryKey(productId, toWarehouseId, transferCondition);
    await Inventory.findOneAndUpdate(
      destKey,
      {
        $inc: { quantity: qty },
        $setOnInsert: {
          productId,
          warehouseId: toWarehouseId,
          condition: transferCondition,
          binLocation: '',
          createdBy: userId,
        },
      },
      { ...sessionOpt, upsert: true, new: true, runValidators: true }
    );

    const storedReason = formatTransferReason({
      quantity: qty,
      productName: product.name,
      fromName: fromWh.name,
      toName: toWh.name,
      userReason: reason,
    });

    const [movement] = await Movement.create(
      [
        {
          productId,
          warehouseId: fromWarehouseId,
          toWarehouseId,
          userId,
          createdBy: userId,
          type: 'TRANSFER',
          quantity: qty,
          delta: 0,
          reason: storedReason,
          source_location:
            String(source_location || fromWh.name || '').trim(),
          destination_location:
            String(destination_location || toWh.name || '').trim(),
          timestamp: new Date(),
        },
      ],
      sessionOpt
    );
    return { movement, isDuplicate: false };
  };

  return withTransferLock(
    transferLockKey(productId, fromWarehouseId, toWarehouseId, userId),
    () => runInventoryOperation(run)
  );
}

module.exports = { recordMovement, recordTransfer };
