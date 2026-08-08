const mongoose = require('mongoose');
const { Product, Warehouse, Inventory, Movement, MOVEMENT_TYPES } = require('../models');
const { CREATED_BY_SELECT, formatCreatedBy, formatPerformedByUser } = require('../utils/createdByDto');
const { formatProduct } = require('../utils/productDto');
const {
  COLLECTIONS,
  leftJoin,
  formatUserDoc,
  formatProductLean,
} = require('../utils/lookupHelpers');
const { recordMovement, recordTransfer } = require('../utils/movementService');
const { formatMovementResponse } = require('../utils/movementDto');
const { buildMovementRouting } = require('../utils/movementRouting');
const { fetchInventoryTrackingRows } = require('../services/inventoryTrackingService');
const {
  syncWarehouseStaffAssignments,
  listStaffCandidates,
  STAFF_SELECT,
  ASSIGNABLE_WAREHOUSE_STAFF_MATCH,
} = require('../services/warehouseStaffService');
const {
  afterInventoryChange,
  notifyWarehouseCreated,
  notifyWarehouseStaffAssignment,
} = require('../services/notificationService');
const { emitInventoryChanged } = require('../realtime/inventoryEmitter');
const { formatWarehouse } = require('../utils/warehouseDto');
const { fetchWarehouseInventoryTotals } = require('../services/warehouseInventoryStats');
const { validateMovementReason } = require('../utils/movementReasonValidation');
const { validateExpiryDates } = require('../utils/expiryStatus');
const { logAudit } = require('../utils/activityLogger');
const { inventoryActionLabel } = require('../constants/audit');
const { buildMovementAuditDetails } = require('../utils/auditHelpers');
const { validateTransferRequest, validatePositiveIntegerQuantity } = require('../utils/stockValidation');
const {
  CONDITION_AVAILABLE,
  CONDITION_DAMAGED,
  CONDITION_INSPECTION,
  normalizeCondition,
  validateConditionRequired,
  assertOutboundAllowed,
} = require('../constants/inventoryConditions');

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

function staffAssignedIds(user) {
  return (user?.assignedWarehouseIds || []).map(String);
}

function staffWarehouseObjectIds(user) {
  return staffAssignedIds(user)
    .filter((id) => isValidObjectId(id))
    .map((id) => new mongoose.Types.ObjectId(id));
}

function emptyInventoryPayload() {
  return { lines: [], items: [], counts: { lines: 0, products: 0 } };
}

function emptyTrackingPayload(assignedWarehouseIds = []) {
  return {
    rows: [],
    summary: {
      total_lines: 0,
      total_units: 0,
      in_stock: 0,
      low_stock: 0,
      out_of_stock: 0,
    },
    expiry_summary: {
      expired: 0,
      expiring_soon: 0,
      expiring_30d: 0,
      safe: 0,
    },
    assignedWarehouseIds,
  };
}

/**
 * Flat inventory lines with LEFT JOIN-style lookups (rows always returned).
 */
async function getInventory(req, res) {
  try {
    const isStaff = req.user?.role === 'Staff';
    const assignedIds = staffWarehouseObjectIds(req.user);

    if (isStaff && assignedIds.length === 0) {
      return res.json(emptyInventoryPayload());
    }

    const pipeline = [];
    if (isStaff && assignedIds.length > 0) {
      pipeline.push({ $match: { warehouseId: { $in: assignedIds } } });
    }
    pipeline.push(
      { $sort: { updatedAt: -1 } },
      ...leftJoin('productId', COLLECTIONS.products, 'product'),
      ...leftJoin('warehouseId', COLLECTIONS.warehouses, 'warehouse'),
      ...leftJoin('createdBy', COLLECTIONS.users, 'creator'),
      {
        $lookup: {
          from: COLLECTIONS.categories,
          localField: 'product.categoryId',
          foreignField: '_id',
          as: 'category',
        },
      },
      {
        $unwind: { path: '$category', preserveNullAndEmptyArrays: true },
      },
      {
        $lookup: {
          from: COLLECTIONS.users,
          localField: 'product.createdBy',
          foreignField: '_id',
          as: 'productCreator',
        },
      },
      {
        $unwind: { path: '$productCreator', preserveNullAndEmptyArrays: true },
      }
    );

    const raw = await Inventory.aggregate(pipeline);

    const lines = raw.map((row) => {
      const product = row.product
        ? formatProductLean({
            ...row.product,
            category: row.category,
            createdBy: row.productCreator,
          })
        : {
            id: row.productId?.toString(),
            _id: row.productId?.toString(),
            sku: '—',
            name: 'Unknown product',
            min_stock_threshold: 0,
            minStockThreshold: 0,
          };

      return {
        id: row._id.toString(),
        productId: product?.id || row.productId?.toString(),
        warehouseId: row.warehouse ? row.warehouse._id.toString() : row.warehouseId?.toString() || null,
        warehouseName: row.warehouse?.name ?? '',
        availableQuantity: row.quantity,
        quantity: row.quantity,
        condition: normalizeCondition(row.condition),
        bin_location: row.binLocation ?? '',
        updated_at: row.updatedAt,
        created_by: formatUserDoc(row.creator),
        product,
        warehouse: row.warehouse
          ? {
              id: row.warehouse._id.toString(),
              _id: row.warehouse._id.toString(),
              name: row.warehouse.name,
              location: row.warehouse.location,
            }
          : null,
      };
    });

    const byProduct = new Map();
    for (const line of lines) {
      const pid = line.product?.id || line.product?._id;
      if (!pid) continue;
      if (!byProduct.has(pid)) {
        byProduct.set(pid, {
          product: line.product,
          totalQuantity: 0,
          warehouses: [],
          created_by: line.created_by || line.product?.created_by,
        });
      }
      const entry = byProduct.get(pid);
      entry.totalQuantity += line.quantity;
      entry.warehouses.push({
        warehouseId: line.warehouseId || line.warehouse?.id,
        warehouse: line.warehouse,
        quantity: line.quantity,
        condition: line.condition,
        binLocation: line.bin_location,
        updatedAt: line.updated_at,
        created_by: line.created_by,
      });
    }

    const missingWarehouse = lines.filter((l) => l.productId && !l.warehouseId).length;
    const missingProduct = lines.filter((l) => !l.productId).length;
    if (missingWarehouse > 0 || missingProduct > 0) {
      console.warn('[getInventory] incomplete records', {
        missingWarehouseLinks: missingWarehouse,
        missingProductLinks: missingProduct,
        totalLines: lines.length,
      });
    }

    return res.json({
      lines,
      items: Array.from(byProduct.values()),
      counts: { lines: lines.length, products: byProduct.size },
    });
  } catch (err) {
    console.error('getInventory error:', err.message);
    return res.status(500).json({ message: 'Failed to load inventory' });
  }
}

async function handleMovement(req, res) {
  const {
    type,
    productId,
    warehouseId,
    fromWarehouseId,
    toWarehouseId,
    quantity,
    targetQuantity,
    reason,
    binLocation,
    referenceNumber,
    destination,
    destinationClient,
    customerName,
    destination_location: destinationLocationBody,
    source_location: sourceLocationBody,
    condition,
    batchNumber,
    manufactureDate,
    expiryDate,
  } = req.body;

  if (!type || !MOVEMENT_TYPES.includes(type)) {
    return res.status(400).json({
      message: `type must be one of: ${MOVEMENT_TYPES.join(', ')}`,
    });
  }

  let lineCondition;
  try {
    lineCondition = validateConditionRequired(condition);
  } catch (err) {
    return res.status(err.status || 400).json({ message: err.message });
  }

  if (type === 'OUTBOUND') {
    try {
      assertOutboundAllowed(lineCondition);
    } catch (err) {
      return res.status(err.status || 400).json({ message: err.message });
    }
  }

  if (!productId || !isValidObjectId(productId)) {
    return res.status(400).json({ message: 'Valid productId is required' });
  }

  const reasonValidationError = validateMovementReason(reason);
  if (reasonValidationError) {
    return res.status(400).json({ message: reasonValidationError });
  }

  const expiryErrors = validateExpiryDates(manufactureDate, expiryDate);
  if (expiryErrors) {
    return res.status(400).json({ message: expiryErrors.join('. ') });
  }

  if (req.user?.role === 'Staff') {
    return res.status(403).json({
      message:
        'Direct inventory operations are not allowed for Staff. Accept and complete the assigned task instead.',
    });
  }

  try {
    if (type === 'TRANSFER') {
      const fromId = fromWarehouseId || warehouseId;
      const toId = toWarehouseId;

      if (!fromId || !toId) {
        return res.status(400).json({
          message: 'fromWarehouseId and toWarehouseId are required for transfers',
        });
      }
      if (!isValidObjectId(fromId) || !isValidObjectId(toId)) {
        return res.status(400).json({ message: 'Invalid warehouse id for transfer' });
      }
      if (String(fromId) === String(toId)) {
        return res.status(400).json({
          message: 'Source and destination warehouses must be different',
        });
      }

      let transferQty;
      try {
        transferQty = validatePositiveIntegerQuantity(quantity);
      } catch (qtyErr) {
        return res.status(qtyErr.status || 400).json({ message: qtyErr.message });
      }

      try {
        await validateTransferRequest({
          productId,
          fromWarehouseId: fromId,
          toWarehouseId: toId,
          quantity: transferQty,
          condition: lineCondition,
        });
      } catch (validationErr) {
        return res.status(validationErr.status || 400).json({ message: validationErr.message });
      }

      const [fromWh, toWh] = await Promise.all([
        Warehouse.findById(fromId).lean(),
        Warehouse.findById(toId).lean(),
      ]);
      if (!fromWh || !toWh) {
        return res.status(400).json({ message: 'Invalid warehouse id for transfer' });
      }

      const routing = buildMovementRouting({
        type: 'TRANSFER',
        fromWarehouseName: fromWh.name,
        toWarehouseName: toWh.name,
      });

      const transferResult = await recordTransfer({
        productId,
        fromWarehouseId: fromId,
        toWarehouseId: toId,
        userId: req.user.id,
        quantity: transferQty,
        reason: String(reason || '').trim(),
        condition: lineCondition,
        source_location: String(sourceLocationBody || routing.source_location).trim(),
        destination_location: String(
          destinationLocationBody || routing.destination_location
        ).trim(),
      });

      const movementDoc = transferResult.movement || transferResult;
      const isDuplicateTransfer = Boolean(transferResult.isDuplicate);

      const populated = await Movement.findById(movementDoc._id)
        .populate('productId', 'sku name')
        .populate('warehouseId', 'name location')
        .populate('toWarehouseId', 'name location')
        .populate('createdBy', CREATED_BY_SELECT)
        .lean();

      if (!isDuplicateTransfer) {
        const productName = populated.productId?.name || populated.productId?.sku || 'Product';
        await logAudit(req, {
          actorId: req.user.id,
          actorRole: req.user.role,
          action: 'Transfer',
          module: 'Inventory',
          entityType: 'movement',
          entityId: movementDoc._id.toString(),
          entityLabel: productName,
          beforeValue: { warehouse: fromWh.name, quantity: transferQty },
          afterValue: { warehouse: toWh.name, quantity: transferQty },
          details: buildMovementAuditDetails({
            type: 'TRANSFER',
            quantity: transferQty,
            product: populated.productId,
            warehouse: fromWh,
            toWarehouse: toWh,
          }),
          warehouseIds: [fromId, toId],
        });
        await afterInventoryChange({
          productId,
          warehouseId: fromId,
          fromWarehouseId: fromId,
          toWarehouseId: toId,
          type: 'TRANSFER',
          quantity,
          condition: lineCondition,
          actorId: req.user.id,
          movementId: movementDoc._id,
          product: populated.productId,
          warehouse: fromWh,
          toWarehouse: toWh,
        });
        emitInventoryChanged({
          type: 'TRANSFER',
          productId,
          warehouseId: fromId,
          toWarehouseId: toId,
        });
      }
      return res.status(201).json({
        movement: formatMovementResponse({
          ...populated,
          id: populated._id.toString(),
          created_by: formatCreatedBy(populated),
          from_warehouse: populated.warehouseId,
          to_warehouse: populated.toWarehouseId,
        }),
        message: 'Stock transferred successfully',
      });
    }

    if (!warehouseId) {
      return res.status(400).json({ message: 'warehouseId is required' });
    }
    if (!isValidObjectId(warehouseId)) {
      return res.status(400).json({ message: 'Invalid warehouseId' });
    }

    const warehouse = await Warehouse.findById(warehouseId).lean();
    if (!warehouse) {
      return res.status(404).json({ message: 'Warehouse not found' });
    }

    const customer =
      String(customerName || destinationLocationBody || destinationClient || destination || '').trim();

    if (type === 'OUTBOUND' && !customer) {
      return res.status(400).json({ message: 'Customer name is required for outbound shipments' });
    }

    let finalReason = String(reason || '').trim();

    const routing = buildMovementRouting({
      type,
      warehouseName: warehouse.name,
      customerName: customer,
    });

    const movementDoc = await recordMovement({
      productId,
      warehouseId,
      userId: req.user.id,
      type,
      quantity,
      targetQuantity,
      reason: finalReason,
      binLocation,
      condition: lineCondition,
      source_location: String(sourceLocationBody || routing.source_location).trim(),
      destination_location: String(
        destinationLocationBody || routing.destination_location
      ).trim(),
      batchNumber: batchNumber || '',
      manufactureDate: manufactureDate || null,
      expiryDate: expiryDate || null,
    });

    const populated = await Movement.findById(movementDoc._id)
      .populate('productId', 'sku name')
      .populate('warehouseId', 'name')
      .populate('createdBy', CREATED_BY_SELECT)
      .lean();

    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: inventoryActionLabel(type),
      module: 'Inventory',
      entityType: 'movement',
      entityId: movementDoc._id.toString(),
      entityLabel: populated.productId?.name || populated.productId?.sku || 'Product',
      afterValue: { type, quantity, warehouse: warehouse.name },
      details: buildMovementAuditDetails({
        type,
        quantity,
        product: populated.productId,
        warehouse,
        customer,
      }),
      warehouseIds: [warehouseId],
    });
    await afterInventoryChange({
      productId,
      warehouseId,
      type,
      quantity,
      condition: lineCondition,
      actorId: req.user.id,
      movementId: movementDoc._id,
      product: populated.productId,
      warehouse,
    });
    emitInventoryChanged({ type, productId, warehouseId });
    return res.status(201).json({
      movement: formatMovementResponse({
        ...populated,
        id: populated._id.toString(),
        created_by: formatCreatedBy(populated),
      }),
      message: 'Movement recorded and inventory updated',
    });
  } catch (err) {
    const status = err.status || 500;
    if (status !== 500) {
      return res.status(status).json({ message: err.message });
    }
    console.error('handleMovement error:', err.message);
    return res.status(500).json({ message: 'Movement failed' });
  }
}

/**
 * Creates sample INBOUND stock + movement when the database has products/warehouses but no stock.
 */
async function seedSampleStock(req, res) {
  try {
    const [product, warehouse] = await Promise.all([
      Product.findOne().sort({ createdAt: 1 }),
      Warehouse.findOne().sort({ createdAt: 1 }),
    ]);

    if (!product) {
      return res.status(400).json({
        message: 'Create at least one product before seeding inventory.',
      });
    }
    if (!warehouse) {
      return res.status(400).json({
        message: 'Create at least one warehouse before seeding inventory.',
      });
    }

    const movement = await recordMovement({
      productId: product._id,
      warehouseId: warehouse._id,
      userId: req.user.id,
      type: 'INBOUND',
      quantity: 25,
      reason: 'Sample stock — thesis demo',
      binLocation: 'A-01',
      condition: CONDITION_AVAILABLE,
    });

    const populated = await Movement.findById(movement._id)
      .populate('productId', 'sku name')
      .populate('warehouseId', 'name')
      .populate('createdBy', CREATED_BY_SELECT)
      .lean();

    return res.status(201).json({
      message: 'Sample inventory and movement created',
      movement: {
        ...populated,
        id: populated._id.toString(),
        created_by: formatCreatedBy(populated),
      },
    });
  } catch (err) {
    console.error('seedSampleStock error:', err.message);
    return res.status(500).json({ message: err.message || 'Seed failed' });
  }
}

const WAREHOUSE_POPULATE = [
  { path: 'createdBy', select: CREATED_BY_SELECT },
  {
    path: 'assignedStaffIds',
    select: STAFF_SELECT,
    match: ASSIGNABLE_WAREHOUSE_STAFF_MATCH,
  },
];

async function listWarehouses(req, res) {
  try {
    const isStaff = req.user?.role === 'Staff';
    const assignedIds = staffWarehouseObjectIds(req.user);
    const filter = isStaff && assignedIds.length > 0 ? { _id: { $in: assignedIds } } : isStaff ? { _id: { $in: [] } } : {};

    const warehouses = await Warehouse.find(filter)
      .populate(WAREHOUSE_POPULATE)
      .sort({ name: 1 })
      .lean();

    const warehouseIds = warehouses.map((w) => w._id);
    const inventoryTotals = await fetchWarehouseInventoryTotals(warehouseIds);

    return res.json({
      warehouses: warehouses.map((warehouse) =>
        formatWarehouse(warehouse, inventoryTotals.get(warehouse._id.toString()))
      ),
    });
  } catch (err) {
    console.error('listWarehouses error:', err.message);
    return res.status(500).json({ message: 'Failed to load warehouses' });
  }
}

async function listWarehouseStaffCandidates(req, res) {
  try {
    const users = await listStaffCandidates(req.query.q);
    return res.json({
      staff: users.map((u) => ({
        id: u._id.toString(),
        username: u.username,
        full_name: u.fullName || '',
        email: u.email,
        role: u.role,
        avatar: u.avatar || '',
        assigned_warehouse_count: (u.assignedWarehouseIds || []).length,
      })),
    });
  } catch (err) {
    console.error('listWarehouseStaffCandidates error:', err.message);
    return res.status(500).json({ message: 'Failed to load staff list' });
  }
}

async function createWarehouse(req, res) {
  try {
    const { name, location, capacity, staff_ids: staffIdsRaw } = req.body;

    if (!name || typeof name !== 'string' || !name.trim()) {
      return res.status(400).json({ message: 'name is required' });
    }
    if (!location || typeof location !== 'string' || !location.trim()) {
      return res.status(400).json({ message: 'location is required' });
    }
    if (capacity == null || capacity === '') {
      return res.status(400).json({ message: 'capacity is required' });
    }

    const cap = Number(capacity);
    if (!Number.isFinite(cap) || cap < 0) {
      return res.status(400).json({ message: 'capacity must be a non-negative number' });
    }

    const warehouse = await Warehouse.create({
      name: name.trim(),
      location: location.trim(),
      capacity: cap,
      createdBy: req.user.id,
      assignedStaffIds: [],
    });

    if (staffIdsRaw != null) {
      try {
        await syncWarehouseStaffAssignments(warehouse._id, staffIdsRaw);
      } catch (syncErr) {
        await Warehouse.findByIdAndDelete(warehouse._id);
        return res.status(syncErr.status || 400).json({ message: syncErr.message });
      }
    }

    const staffCount = Array.isArray(staffIdsRaw) ? staffIdsRaw.length : 0;
    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: 'Create',
      module: 'Warehouse',
      entityType: 'warehouse',
      entityId: warehouse._id.toString(),
      entityLabel: warehouse.name,
      afterValue: { name: warehouse.name, location: warehouse.location, capacity: warehouse.capacity },
      details: `${warehouse.name} (${warehouse.location})${staffCount ? ` · ${staffCount} staff assigned` : ''}`,
      warehouseIds: [warehouse._id],
    });

    const populated = await Warehouse.findById(warehouse._id).populate(WAREHOUSE_POPULATE).lean();
    await notifyWarehouseCreated({
      warehouse: populated,
      actorId: req.user.id,
      actorName: req.user.username,
    });
    if (staffIdsRaw != null) {
      await notifyWarehouseStaffAssignment({
        warehouse: populated,
        staffIds: (populated.assignedStaffIds || []).map((id) => id.toString()),
        previousIds: [],
        actorId: req.user.id,
      });
    }

    return res.status(201).json({
      warehouse: formatWarehouse(populated),
    });
  } catch (err) {
    console.error('createWarehouse error:', err.message);
    return res.status(500).json({ message: 'Failed to create warehouse' });
  }
}

async function updateWarehouse(req, res) {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid warehouse id' });
    }

    const warehouse = await Warehouse.findById(id);
    if (!warehouse) {
      return res.status(404).json({ message: 'Warehouse not found' });
    }

    const { name, location, capacity, staff_ids: staffIdsRaw } = req.body;

    if (name !== undefined) {
      if (!String(name).trim()) return res.status(400).json({ message: 'name is required' });
      warehouse.name = String(name).trim();
    }
    if (location !== undefined) {
      if (!String(location).trim()) return res.status(400).json({ message: 'location is required' });
      warehouse.location = String(location).trim();
    }
    if (capacity !== undefined) {
      const cap = Number(capacity);
      if (!Number.isFinite(cap) || cap < 0) {
        return res.status(400).json({ message: 'capacity must be a non-negative number' });
      }
      warehouse.capacity = cap;
    }

    const previousStaffIds = (warehouse.assignedStaffIds || []).map((id) => id.toString());

    await warehouse.save();

    if (staffIdsRaw !== undefined) {
      try {
        await syncWarehouseStaffAssignments(warehouse._id, staffIdsRaw);
      } catch (syncErr) {
        return res.status(syncErr.status || 400).json({ message: syncErr.message });
      }
    }

    const populated = await Warehouse.findById(warehouse._id).populate(WAREHOUSE_POPULATE).lean();

    await logAudit(req, {
      actorId: req.user.id,
      actorRole: req.user.role,
      action: staffIdsRaw !== undefined ? 'Warehouse Assignment' : 'Update',
      module: 'Warehouse',
      entityType: 'warehouse',
      entityId: warehouse._id.toString(),
      entityLabel: warehouse.name,
      beforeValue: staffIdsRaw !== undefined ? { staffIds: previousStaffIds } : undefined,
      afterValue: staffIdsRaw !== undefined
        ? { staffIds: (populated.assignedStaffIds || []).map((sid) => sid.toString()) }
        : { name: warehouse.name, location: warehouse.location },
      details: warehouse.name,
      warehouseIds: [warehouse._id],
    });
    if (staffIdsRaw !== undefined) {
      await notifyWarehouseStaffAssignment({
        warehouse: populated,
        staffIds: (populated.assignedStaffIds || []).map((id) => id.toString()),
        previousIds: previousStaffIds,
        actorId: req.user.id,
      });
    }
    return res.json({ warehouse: formatWarehouse(populated) });
  } catch (err) {
    console.error('updateWarehouse error:', err.message);
    return res.status(500).json({ message: 'Failed to update warehouse' });
  }
}

async function listMovements(req, res) {
  try {
    const raw = parseInt(String(req.query.limit || '100'), 10);
    const limit = Math.min(Math.max(Number.isFinite(raw) ? raw : 100, 1), 500);
    const isStaff = req.user?.role === 'Staff';
    const assignedIds = staffWarehouseObjectIds(req.user);

    if (isStaff && assignedIds.length === 0) {
      return res.json({ movements: [], counts: { movements: 0 } });
    }

    const pipeline = [];
    if (isStaff && assignedIds.length > 0) {
      pipeline.push({
        $match: {
          $or: [{ warehouseId: { $in: assignedIds } }, { toWarehouseId: { $in: assignedIds } }],
        },
      });
    }
    pipeline.push(
      { $sort: { createdAt: -1 } },
      { $limit: limit },
      ...leftJoin('productId', COLLECTIONS.products, 'product'),
      ...leftJoin('warehouseId', COLLECTIONS.warehouses, 'warehouse'),
      ...leftJoin('toWarehouseId', COLLECTIONS.warehouses, 'toWarehouse'),
      ...leftJoin('createdBy', COLLECTIONS.users, 'creator'),
      {
        $lookup: {
          from: COLLECTIONS.users,
          localField: 'userId',
          foreignField: '_id',
          as: 'performer',
        },
      },
      {
        $unwind: { path: '$performer', preserveNullAndEmptyArrays: true },
      }
    );

    const rows = await Movement.aggregate(pipeline);

    const movements = rows.map((m) =>
      formatMovementResponse({
        _id: m._id,
        id: m._id.toString(),
        type: m.type,
        quantity: m.quantity,
        delta: m.delta,
        reason: m.reason,
        source_location: m.source_location ?? '',
        destination_location: m.destination_location ?? '',
        timestamp: m.timestamp,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
        createdBy: m.createdBy,
        userId: m.userId,
        creator: m.creator,
        performer: m.performer,
        productId: m.product
          ? { _id: m.product._id, sku: m.product.sku, name: m.product.name }
          : m.productId,
        warehouseId: m.warehouse
          ? { _id: m.warehouse._id, name: m.warehouse.name, location: m.warehouse.location }
          : m.warehouseId,
        toWarehouseId: m.toWarehouse
          ? {
              _id: m.toWarehouse._id,
              name: m.toWarehouse.name,
              location: m.toWarehouse.location,
            }
          : m.toWarehouseId,
        from_warehouse: m.warehouse
          ? { _id: m.warehouse._id, name: m.warehouse.name, location: m.warehouse.location }
          : null,
        to_warehouse: m.toWarehouse
          ? {
              _id: m.toWarehouse._id,
              name: m.toWarehouse.name,
              location: m.toWarehouse.location,
            }
          : null,
      })
    );

    return res.json({ movements, counts: { movements: movements.length } });
  } catch (err) {
    console.error('listMovements error:', err.message);
    return res.status(500).json({ message: 'Failed to load movements' });
  }
}

/**
 * Aggregated warehouse stock for Inventory Tracking (product × warehouse).
 */
async function getInventoryTracking(req, res) {
  try {
    let warehouseFilter = req.query.warehouse_id || req.query.warehouseId;
    const q = req.query.q || '';
    const expiryFilter = req.query.expiry_filter || '';

    const isStaff = req.user?.role === 'Staff';
    const assignedWarehouses = staffAssignedIds(req.user);

    if (isStaff && assignedWarehouses.length === 0) {
      return res.json(emptyTrackingPayload([]));
    }

    if (isStaff && warehouseFilter && !assignedWarehouses.includes(String(warehouseFilter))) {
      return res.json(emptyTrackingPayload(assignedWarehouses));
    }

    if (isStaff && !warehouseFilter && assignedWarehouses.length === 1) {
      warehouseFilter = assignedWarehouses[0];
    }

    const warehouseIds =
      isStaff && !warehouseFilter && assignedWarehouses.length > 1
        ? assignedWarehouses
        : undefined;

    let { rows, summary, expiry_summary } = await fetchInventoryTrackingRows({
      warehouseId: warehouseFilter,
      warehouseIds,
      q,
      expiryFilter,
    });

    return res.json({ rows, summary, expiry_summary, assignedWarehouseIds: isStaff ? assignedWarehouses.map(String) : undefined });
  } catch (err) {
    console.error('getInventoryTracking error:', err.message);
    return res.status(500).json({ message: 'Failed to load inventory tracking' });
  }
}

async function getWarehouseStock(req, res) {
  try {
    const { warehouse_id: warehouseId, product_id: productId } = req.query;
    if (!warehouseId || !isValidObjectId(warehouseId)) {
      return res.status(400).json({ message: 'warehouse_id is required' });
    }

    const match = { warehouseId: new mongoose.Types.ObjectId(warehouseId) };
    if (productId && isValidObjectId(productId)) {
      match.productId = new mongoose.Types.ObjectId(productId);
    }

    const lines = await Inventory.aggregate([
      { $match: match },
      {
        $lookup: {
          from: 'products',
          localField: 'productId',
          foreignField: '_id',
          as: 'prod',
        },
      },
      { $unwind: { path: '$prod', preserveNullAndEmptyArrays: true } },
      {
        $project: {
          product_id: '$productId',
          product_name: '$prod.name',
          product_sku: '$prod.sku',
          quantity: 1,
          condition: 1,
          min_stock_threshold: '$prod.minStockThreshold',
        },
      },
      { $sort: { 'product_name': 1, condition: 1 } },
    ]);

    if (productId) {
      const available = lines.filter((l) => l.condition === 'Available').reduce((s, l) => s + l.quantity, 0);
      const damaged = lines.filter((l) => l.condition === 'Damaged').reduce((s, l) => s + l.quantity, 0);
      const inspection = lines.filter((l) => l.condition === 'Inspection').reduce((s, l) => s + l.quantity, 0);
      const total = lines.reduce((s, l) => s + l.quantity, 0);
      const threshold = lines[0]?.min_stock_threshold ?? 0;
      return res.json({
        product_id: productId,
        warehouse_id: warehouseId,
        available,
        damaged,
        inspection,
        total,
        min_stock_threshold: threshold,
        low_stock: available > 0 && available <= threshold,
        out_of_stock: available === 0,
      });
    }

    const byProduct = new Map();
    for (const l of lines) {
      const pid = l.product_id.toString();
      if (!byProduct.has(pid)) {
        byProduct.set(pid, {
          product_id: pid,
          product_name: l.product_name || '—',
          product_sku: l.product_sku || '—',
          total: 0,
          available: 0,
        });
      }
      const entry = byProduct.get(pid);
      entry.total += l.quantity;
      if (l.condition === 'Available') entry.available += l.quantity;
    }

    return res.json({
      warehouse_id: warehouseId,
      products: Array.from(byProduct.values()).sort((a, b) => a.product_name.localeCompare(b.product_name)),
    });
  } catch (err) {
    console.error('getWarehouseStock error:', err.message);
    return res.status(500).json({ message: 'Failed to load warehouse stock' });
  }
}

async function getProductAvailability(req, res) {
  try {
    const { product_id: productId } = req.query;
    if (!productId || !isValidObjectId(productId)) {
      return res.status(400).json({ message: 'product_id is required' });
    }

    const isStaff = req.user?.role === 'Staff';
    const assignedIds = staffWarehouseObjectIds(req.user);

    if (isStaff && assignedIds.length === 0) {
      console.warn('[getProductAvailability] staff user has no assigned warehouses', {
        userId: req.user?.id,
        productId,
      });
      return res.json({
        product_id: productId,
        product_name: '',
        product_sku: '',
        min_stock_threshold: 0,
        total_available: 0,
        warehouses: [],
      });
    }

    const match = { productId: new mongoose.Types.ObjectId(productId) };
    if (isStaff && assignedIds.length > 0) {
      match.warehouseId = { $in: assignedIds };
    }

    const rows = await Inventory.aggregate([
      { $match: match },
      {
        $lookup: {
          from: 'warehouses',
          localField: 'warehouseId',
          foreignField: '_id',
          as: 'wh',
        },
      },
      { $unwind: { path: '$wh', preserveNullAndEmptyArrays: true } },
      {
        $lookup: {
          from: 'products',
          localField: 'productId',
          foreignField: '_id',
          as: 'prod',
        },
      },
      { $unwind: { path: '$prod', preserveNullAndEmptyArrays: true } },
      {
        $project: {
          warehouse_id: '$warehouseId',
          warehouse_name: '$wh.name',
          warehouse_location: '$wh.location',
          quantity: 1,
          condition: 1,
          product_name: '$prod.name',
          product_sku: '$prod.sku',
          min_stock_threshold: '$prod.minStockThreshold',
        },
      },
    ]);

    const byWarehouse = new Map();
    let productName = '';
    let productSku = '';
    let threshold = 0;

    for (const r of rows) {
      if (!productName) { productName = r.product_name || ''; productSku = r.product_sku || ''; threshold = r.min_stock_threshold ?? 0; }
      const wid = r.warehouse_id.toString();
      if (!byWarehouse.has(wid)) {
        byWarehouse.set(wid, {
          warehouse_id: wid,
          warehouse_name: r.warehouse_name || '—',
          warehouse_location: r.warehouse_location || '',
          available: 0,
          damaged: 0,
          inspection: 0,
          total: 0,
        });
      }
      const entry = byWarehouse.get(wid);
      entry.total += r.quantity;
      const cond = normalizeCondition(r.condition);
      if (cond === normalizeCondition(CONDITION_AVAILABLE)) entry.available += r.quantity;
      else if (cond === normalizeCondition(CONDITION_DAMAGED)) entry.damaged += r.quantity;
      else if (cond === normalizeCondition(CONDITION_INSPECTION)) entry.inspection += r.quantity;
    }

    const warehouses = Array.from(byWarehouse.values())
      .map((w) => ({
        ...w,
        low_stock: w.available > 0 && w.available <= threshold,
        out_of_stock: w.available === 0,
      }))
      .sort((a, b) => b.available - a.available);

    const totalAvailable = warehouses.reduce((s, w) => s + w.available, 0);

    if (warehouses.length === 0) {
      console.debug('[getProductAvailability] no warehouse stock rows', {
        productId,
        inventoryRows: rows.length,
        isStaff,
        assignedWarehouseCount: assignedIds.length,
      });
    }

    return res.json({
      product_id: productId,
      product_name: productName,
      product_sku: productSku,
      min_stock_threshold: threshold,
      total_available: totalAvailable,
      warehouses: warehouses.map((w) => ({
        ...w,
        warehouseId: w.warehouse_id,
        warehouseName: w.warehouse_name,
        availableQuantity: w.available,
      })),
    });
  } catch (err) {
    console.error('getProductAvailability error:', err.message);
    return res.status(500).json({ message: 'Failed to load product availability' });
  }
}

module.exports = {
  getInventory,
  getInventoryTracking,
  handleMovement,
  seedSampleStock,
  listWarehouses,
  listWarehouseStaffCandidates,
  createWarehouse,
  updateWarehouse,
  listMovements,
  getWarehouseStock,
  getProductAvailability,
};
