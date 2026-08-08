const mongoose = require('mongoose');

/**
 * Connects to MongoDB using MONGO_URI (or legacy MONGODB_URI).
 * @returns {Promise<typeof mongoose>}
 */
async function connectDB() {
  const uri = process.env.MONGO_URI || process.env.MONGODB_URI;

  if (!uri) {
    throw new Error('MONGO_URI is not defined in environment variables');
  }

  mongoose.set('strictQuery', true);

  await mongoose.connect(uri);

  await migrateManagerToSupervisor();
  await migrateInventoryConditions();
  await migrateProductCatalogFields();
  await migrateMovementLocations();
  await migrateUserProfileFields();
  await migrateWarehouseStaffFields();
  await migrateSyncStaffWarehouseAssignments();
  await migrateLegacyOrderNumbers();

  return mongoose;
}

async function migrateLegacyOrderNumbers() {
  const { migrateLegacyOrderNumbers: run } = require('../utils/orderNumber');
  await run();
}

async function migrateWarehouseStaffFields() {
  const { Warehouse, User } = require('../models');
  const [wh, users] = await Promise.all([
    Warehouse.updateMany({ assignedStaffIds: { $exists: false } }, { $set: { assignedStaffIds: [] } }),
    User.updateMany({ assignedWarehouseIds: { $exists: false } }, { $set: { assignedWarehouseIds: [] } }),
  ]);
  if (wh.modifiedCount > 0) {
    console.log(`Migrated ${wh.modifiedCount} warehouse(s) with assignedStaffIds`);
  }
  if (users.modifiedCount > 0) {
    console.log(`Migrated ${users.modifiedCount} user(s) with assignedWarehouseIds`);
  }
}

/** Backfill user.assignedWarehouseIds from warehouse.assignedStaffIds (idempotent). */
async function migrateSyncStaffWarehouseAssignments() {
  const { Warehouse, User } = require('../models');
  const warehouses = await Warehouse.find({
    assignedStaffIds: { $exists: true, $not: { $size: 0 } },
  })
    .select('assignedStaffIds')
    .lean();

  let synced = 0;
  for (const wh of warehouses) {
    const staffIds = (wh.assignedStaffIds || []).filter(Boolean);
    if (!staffIds.length) continue;
    const result = await User.updateMany(
      { _id: { $in: staffIds }, role: 'Staff' },
      { $addToSet: { assignedWarehouseIds: wh._id } }
    );
    synced += result.modifiedCount;
  }
  if (synced > 0) {
    console.log(`Synced assignedWarehouseIds for ${synced} staff user(s) from warehouse assignments`);
  }
}

async function migrateUserProfileFields() {
  const { User } = require('../models');
  const result = await User.updateMany(
    {
      $or: [
        { fullName: { $exists: false } },
        { phone: { $exists: false } },
        { avatar: { $exists: false } },
        { preferences: { $exists: false } },
      ],
    },
    { $set: { fullName: '', phone: '', avatar: '', preferences: null } }
  );
  if (result.modifiedCount > 0) {
    console.log(`Migrated ${result.modifiedCount} user(s) with profile fields`);
  }
}

/**
 * One-time style migration: legacy "Manager" → "Supervisor".
 */
async function migrateManagerToSupervisor() {
  const { User } = require('../models');
  const result = await User.updateMany({ role: 'Manager' }, { $set: { role: 'Supervisor' } });
  if (result.modifiedCount > 0) {
    console.log(
      `Migrated ${result.modifiedCount} user(s) from Manager to Supervisor`
    );
  }
}

/**
 * Backfill condition on legacy lines and rebuild compound unique index.
 */
async function migrateInventoryConditions() {
  const { Inventory } = require('../models');
  const { CONDITION_AVAILABLE } = require('../constants/inventoryConditions');

  const result = await Inventory.updateMany(
    {
      $or: [
        { condition: { $exists: false } },
        { condition: null },
        { condition: '' },
      ],
    },
    { $set: { condition: CONDITION_AVAILABLE } }
  );

  try {
    await Inventory.collection.dropIndex('productId_1_warehouseId_1');
  } catch {
    /* index may not exist */
  }

  await Inventory.syncIndexes();

  if (result.modifiedCount > 0) {
    console.log(
      `Migrated ${result.modifiedCount} inventory line(s) with default condition "${CONDITION_AVAILABLE}"`
    );
  }
}

async function migrateProductCatalogFields() {
  const { Product } = require('../models');
  const result = await Product.updateMany(
    {
      $or: [
        { barcode: { $exists: false } },
        { imageUrl: { $exists: false } },
      ],
    },
    { $set: { barcode: '', imageUrl: '' } }
  );
  if (result.modifiedCount > 0) {
    console.log(
      `Migrated ${result.modifiedCount} product(s) with catalog fields (barcode, imageUrl)`
    );
  }
}

/**
 * Backfill source_location / destination_location on legacy movement rows.
 */
async function migrateMovementLocations() {
  const { Movement, Warehouse } = require('../models');
  const { buildMovementRouting } = require('../utils/movementRouting');
  const { INBOUND_SOURCE_LOCATION } = require('../constants/movementLocations');

  const cursor = Movement.find({
    $or: [
      { source_location: { $exists: false } },
      { destination_location: { $exists: false } },
      { source_location: null },
      { destination_location: null },
      { source_location: '' },
      { destination_location: '' },
    ],
  })
    .populate('warehouseId', 'name')
    .populate('toWarehouseId', 'name')
    .cursor();

  let updated = 0;
  for await (const m of cursor) {
    const whName = m.warehouseId?.name || '';
    const toName = m.toWarehouseId?.name || '';
    let patch = null;

    if (m.type === 'TRANSFER' && whName && toName) {
      patch = buildMovementRouting({
        type: 'TRANSFER',
        fromWarehouseName: whName,
        toWarehouseName: toName,
      });
    } else if ((m.type === 'INBOUND' || m.type === 'RETURN') && whName) {
      patch = {
        source_location: INBOUND_SOURCE_LOCATION,
        destination_location: whName,
      };
    } else if (m.type === 'OUTBOUND' && whName) {
      const destMatch = String(m.reason || '').match(/Shipped to (.+)$/i);
      patch = {
        source_location: whName,
        destination_location: destMatch?.[1]?.trim() || '',
      };
    } else if (m.type === 'ADJUSTMENT' && whName) {
      patch = { source_location: whName, destination_location: whName };
    }

    if (patch) {
      await Movement.updateOne({ _id: m._id }, { $set: patch });
      updated += 1;
    }
  }

  if (updated > 0) {
    console.log(`Migrated ${updated} movement(s) with routing locations`);
  }
}

module.exports = { connectDB };
