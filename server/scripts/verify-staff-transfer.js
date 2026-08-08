require('dotenv').config();
const mongoose = require('mongoose');
const { connectDB } = require('../config/db');
const { signAccessToken } = require('../utils/jwt');
const { Inventory, Movement, UserActivityLog } = require('../models');

const BASE = 'http://localhost:5000';
const MUSE_ID = '6a0dda6bf8cd88d7f2a2bce9';
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

async function main() {
  await connectDB();

  const beforeBakaaro = await getQty(BAKAARO);
  const beforeSuuq = await getQty(SUUQBACAAD);
  console.log('Before — Bakaaro:', beforeBakaaro, 'Suuqbacaad:', beforeSuuq);

  const token = signAccessToken({ sub: MUSE_ID, role: 'Staff' });
  const payload = {
    type: 'TRANSFER',
    productId: PRODUCT,
    fromWarehouseId: BAKAARO,
    toWarehouseId: SUUQBACAAD,
    quantity: 4,
    reason: 'Staff transfer verification test',
    condition: CONDITION,
    source_location: 'Bakaaro',
    destination_location: 'Suuqbacaad',
  };

  console.log('\n=== REQUEST ===');
  console.log('POST /api/inventory/movements');
  console.log(JSON.stringify(payload, null, 2));

  const res = await fetch(`${BASE}/api/inventory/movements`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  const bodyText = await res.text();
  console.log('\n=== RESPONSE ===');
  console.log('Status:', res.status);
  let body;
  try {
    body = JSON.parse(bodyText);
    console.log(JSON.stringify(body, null, 2));
  } catch {
    console.log(bodyText);
    process.exit(1);
  }

  if (res.status !== 201) {
    process.exit(1);
  }

  const movementId = body.movement?.id || body.movement?._id;
  const afterBakaaro = await getQty(BAKAARO);
  const afterSuuq = await getQty(SUUQBACAAD);

  console.log('\n=== INVENTORY AFTER ===');
  console.log('Bakaaro:', afterBakaaro, `(expected ${beforeBakaaro - 4})`);
  console.log('Suuqbacaad:', afterSuuq, `(expected ${beforeSuuq + 4})`);

  const movement = await Movement.findById(movementId).lean();
  console.log('\n=== MOVEMENT RECORD ===');
  console.log(movement ? 'Created: yes' : 'Created: NO');
  if (movement) {
    console.log({
      type: movement.type,
      quantity: movement.quantity,
      from: String(movement.warehouseId),
      to: String(movement.toWarehouseId),
      createdBy: String(movement.createdBy),
    });
  }

  const audit = await UserActivityLog.findOne({
    actorId: MUSE_ID,
    action: 'Transferred stock',
    module: 'Inventory',
  })
    .sort({ createdAt: -1 })
    .lean();

  console.log('\n=== AUDIT LOG ===');
  console.log(audit ? 'Created: yes' : 'Created: NO');
  if (audit) console.log({ action: audit.action, details: audit.details });

  const ok =
    afterBakaaro === beforeBakaaro - 4 &&
    afterSuuq === beforeSuuq + 4 &&
    movement &&
    audit;

  console.log('\n=== VERIFICATION ===', ok ? 'PASS' : 'FAIL');
  await mongoose.disconnect();
  process.exit(ok ? 0 : 1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
