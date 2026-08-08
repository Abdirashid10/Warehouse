require('dotenv').config();
const mongoose = require('mongoose');
const { connectDB } = require('../config/db');
const { signAccessToken } = require('../utils/jwt');
const { Inventory, Movement, Product, Warehouse } = require('../models');

const BASE = 'http://localhost:5000';
const BAKAARO = '6a070962aaefe07a1e2cba07';
const SUUQBACAAD = '6a073750fd10f353fc03b320';
const CONDITION = 'Available / Good';
const ADMIN_ID = '6a062102ef49d5a9fcfde319';

async function sumConditionQty(productId, warehouseId, condition) {
  const lines = await Inventory.find({ productId, warehouseId, condition }).lean();
  return {
    total: lines.reduce((s, l) => s + (l.quantity || 0), 0),
    lines: lines.map((l) => ({ id: String(l._id), qty: l.quantity })),
  };
}

async function setExactQty(productId, warehouseId, qty) {
  await Inventory.deleteMany({ productId, warehouseId, condition: CONDITION });
  await Inventory.create({
    productId,
    warehouseId,
    condition: CONDITION,
    quantity: qty,
    createdBy: ADMIN_ID,
  });
}

async function transfer(token, productId, qty) {
  const payload = {
    type: 'TRANSFER',
    productId: String(productId),
    fromWarehouseId: BAKAARO,
    toWarehouseId: SUUQBACAAD,
    quantity: qty,
    reason: 'Transfer quantity audit test run',
    condition: CONDITION,
    source_location: 'Bakaaro',
    destination_location: 'Suuqbacaad',
  };

  const before = await sumConditionQty(productId, BAKAARO, CONDITION);
  const movementCountBefore = await Movement.countDocuments({
    type: 'TRANSFER',
    productId,
    warehouseId: BAKAARO,
    toWarehouseId: SUUQBACAAD,
  });

  const res = await fetch(`${BASE}/api/inventory/movements`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  const body = await res.json();
  const after = await sumConditionQty(productId, BAKAARO, CONDITION);
  const movementCountAfter = await Movement.countDocuments({
    type: 'TRANSFER',
    productId,
    warehouseId: BAKAARO,
    toWarehouseId: SUUQBACAAD,
  });

  const expected = before.total - qty;
  const pass = res.status === 201 && after.total === expected && movementCountAfter === movementCountBefore + 1;

  return {
    start: before.total,
    transfer: qty,
    expected,
    actual: after.total,
    status: res.status,
    movementsCreated: movementCountAfter - movementCountBefore,
    pass,
    body: pass ? undefined : body,
    beforeLines: before.lines,
    afterLines: after.lines,
  };
}

async function main() {
  await connectDB();
  const token = signAccessToken({ sub: ADMIN_ID, role: 'Admin' });

  let product = await Product.findOne().sort({ createdAt: 1 }).lean();
  if (!product) throw new Error('No product found');

  const tests = [
    { start: 7, transfer: 3, expected: 4 },
    { start: 10, transfer: 2, expected: 8 },
    { start: 15, transfer: 5, expected: 10 },
  ];

  console.log('Product:', product.sku, product._id.toString());
  console.log('Route: POST /api/inventory/movements\n');

  for (const t of tests) {
    await setExactQty(product._id, BAKAARO, t.start);
    const result = await transfer(token, product._id, t.transfer);
    console.log(`Test ${t.start} - ${t.transfer} = ${t.expected}`);
    console.log('  Before stock:', result.start);
    console.log('  Transfer qty:', result.transfer);
    console.log('  Expected after:', result.expected);
    console.log('  Actual after:', result.actual);
    console.log('  HTTP status:', result.status);
    console.log('  Movements created:', result.movementsCreated);
    console.log('  Inventory lines before:', result.beforeLines);
    console.log('  Inventory lines after:', result.afterLines);
    console.log('  Result:', result.pass ? 'PASS' : 'FAIL');
    if (result.body) console.log('  Error body:', result.body);
    console.log('');
  }

  // Check duplicate inventory keys
  const dupes = await Inventory.aggregate([
    {
      $group: {
        _id: { p: '$productId', w: '$warehouseId', c: '$condition' },
        count: { $sum: 1 },
        qty: { $sum: '$quantity' },
      },
    },
    { $match: { count: { $gt: 1 } } },
  ]);
  console.log('Duplicate inventory keys in DB:', dupes.length ? dupes : 'none');

  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
