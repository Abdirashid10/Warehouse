require('dotenv').config();
const mongoose = require('mongoose');
const { connectDB } = require('../config/db');
const { signAccessToken } = require('../utils/jwt');
const { User, Inventory, Movement, UserActivityLog } = require('../models');

const BASE = 'http://localhost:5000';
const BAKAARO = '6a070962aaefe07a1e2cba07';
const SUUQBACAAD = '6a073750fd10f353fc03b320';
const PRODUCT = '6a07371bfd10f353fc03b312';
const CONDITION = 'Available / Good';

async function getQty(warehouseId) {
  const line = await Inventory.findOne({
    productId: PRODUCT,
    warehouseId,
    condition: CONDITION,
  }).lean();
  return line?.quantity ?? 0;
}

async function transferAs({ label, userId, role }) {
  const token = signAccessToken({ sub: userId, role });
  const payload = {
    type: 'TRANSFER',
    productId: PRODUCT,
    fromWarehouseId: BAKAARO,
    toWarehouseId: SUUQBACAAD,
    quantity: 1,
    reason: `${label} transfer role verification`,
    condition: CONDITION,
    source_location: 'Bakaaro',
    destination_location: 'Suuqbacaad',
  };

  console.log(`\n=== ${label} (${role}) ===`);
  console.log('POST /api/inventory/movements');
  console.log('Payload:', JSON.stringify(payload));

  const res = await fetch(`${BASE}/api/inventory/movements`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  const text = await res.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = text;
  }

  console.log('Status:', res.status);
  console.log('Response:', typeof body === 'string' ? body : JSON.stringify(body, null, 2));

  return { label, role, status: res.status, body, ok: res.status === 201 };
}

async function main() {
  await connectDB();

  const users = await User.find({ role: { $in: ['Staff', 'Admin', 'Supervisor'] } })
    .select('username email role _id assignedWarehouseIds')
    .lean();

  console.log('Users:');
  for (const u of users) {
    console.log(`  ${u.role}: ${u.username} (${u.email}) id=${u._id}`);
  }

  const muse = users.find((u) => u.username === 'Muse' && u.role === 'Staff');
  const admin = users.find((u) => u.role === 'Admin');
  const supervisor = users.find((u) => u.role === 'Supervisor');

  if (!muse) throw new Error('Staff user Muse not found');
  if (!admin) throw new Error('Admin user not found');

  const beforeBakaaro = await getQty(BAKAARO);
  const beforeSuuq = await getQty(SUUQBACAAD);
  console.log('\nInventory before — Bakaaro:', beforeBakaaro, 'Suuqbacaad:', beforeSuuq);

  const results = [];
  results.push(await transferAs({ label: 'Staff', userId: String(muse._id), role: 'Staff' }));
  results.push(await transferAs({ label: 'Admin', userId: String(admin._id), role: 'Admin' }));
  if (supervisor) {
    results.push(
      await transferAs({ label: 'Supervisor', userId: String(supervisor._id), role: 'Supervisor' })
    );
  }

  const afterBakaaro = await getQty(BAKAARO);
  const afterSuuq = await getQty(SUUQBACAAD);
  const transfersOk = results.filter((r) => r.ok).length;
  const expectedDelta = transfersOk;

  console.log('\n=== INVENTORY AFTER ===');
  console.log('Bakaaro:', afterBakaaro, `(expected ${beforeBakaaro - expectedDelta})`);
  console.log('Suuqbacaad:', afterSuuq, `(expected ${beforeSuuq + expectedDelta})`);

  const lastMovement = await Movement.findOne({ type: 'TRANSFER', productId: PRODUCT })
    .sort({ createdAt: -1 })
    .lean();
  console.log('\n=== LAST MOVEMENT ===');
  console.log(lastMovement ? 'yes' : 'no', lastMovement && {
    id: String(lastMovement._id),
    type: lastMovement.type,
    quantity: lastMovement.quantity,
    createdBy: String(lastMovement.createdBy),
  });

  const lastAudit = await UserActivityLog.findOne({ action: 'Transferred stock', module: 'Inventory' })
    .sort({ createdAt: -1 })
    .lean();
  console.log('\n=== LAST AUDIT LOG ===');
  console.log(lastAudit ? 'yes' : 'no', lastAudit && {
    action: lastAudit.action,
    details: lastAudit.details,
    actorId: String(lastAudit.actorId),
  });

  console.log('\n=== SUMMARY ===');
  for (const r of results) {
    console.log(`${r.role}: HTTP ${r.status} ${r.ok ? 'PASS' : 'FAIL'}`);
  }

  const inventoryOk =
    afterBakaaro === beforeBakaaro - expectedDelta &&
    afterSuuq === beforeSuuq + expectedDelta;

  console.log('Inventory update:', inventoryOk ? 'PASS' : 'FAIL');
  console.log('Movement record:', lastMovement ? 'PASS' : 'FAIL');
  console.log('Audit log:', lastAudit ? 'PASS' : 'FAIL');

  await mongoose.disconnect();
  const allPass = results.every((r) => r.ok) && inventoryOk && lastMovement && lastAudit;
  process.exit(allPass ? 0 : 1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
