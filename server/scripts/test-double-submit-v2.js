require('dotenv').config();
const mongoose = require('mongoose');
const { connectDB } = require('../config/db');
const { signAccessToken } = require('../utils/jwt');
const { Inventory, Movement, Product } = require('../models');

const BASE = 'http://localhost:5000';
const BAKAARO = '6a070962aaefe07a1e2cba07';
const SUUQBACAAD = '6a073750fd10f353fc03b320';
const CONDITION = 'Available / Good';
const ADMIN_ID = '6a062102ef49d5a9fcfde319';

async function qty(productId) {
  const lines = await Inventory.find({ productId, warehouseId: BAKAARO, condition: CONDITION }).lean();
  return lines.reduce((s, l) => s + l.quantity, 0);
}

async function post(token, productId, n) {
  const res = await fetch(`${BASE}/api/inventory/movements`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify({
      type: 'TRANSFER',
      productId: String(productId),
      fromWarehouseId: BAKAARO,
      toWarehouseId: SUUQBACAAD,
      quantity: 3,
      reason: `Double submit test ${n}`,
      condition: CONDITION,
    }),
  });
  return { status: res.status, body: await res.json() };
}

async function main() {
  await connectDB();
  const token = signAccessToken({ sub: ADMIN_ID, role: 'Admin' });
  const product = await Product.findOne().lean();

  await Inventory.deleteMany({ productId: product._id, warehouseId: BAKAARO });
  await Inventory.create({
    productId: product._id,
    warehouseId: BAKAARO,
    condition: CONDITION,
    quantity: 7,
    createdBy: ADMIN_ID,
  });

  // Clear recent duplicate movements for this product
  await Movement.deleteMany({
    type: 'TRANSFER',
    productId: product._id,
    warehouseId: BAKAARO,
    quantity: 3,
    createdAt: { $gte: new Date(Date.now() - 600000) },
  });

  console.log('Before:', await qty(product._id));

  const [a, b] = await Promise.all([post(token, product._id, 1), post(token, product._id, 2)]);
  console.log('Parallel A:', a.status, a.body.message);
  console.log('Parallel B:', b.status, b.body.message);
  console.log('After parallel:', await qty(product._id), '(expect 4)');

  await Inventory.updateOne(
    { productId: product._id, warehouseId: BAKAARO, condition: CONDITION },
    { quantity: 7 }
  );
  await Movement.deleteMany({
    type: 'TRANSFER',
    productId: product._id,
    warehouseId: BAKAARO,
    quantity: 3,
  });

  console.log('\nBefore sequential:', await qty(product._id));
  const s1 = await post(token, product._id, 3);
  const s2 = await post(token, product._id, 4);
  console.log('Sequential 1:', s1.status);
  console.log('Sequential 2:', s2.status);
  console.log('After sequential:', await qty(product._id), '(expect 4)');

  const movementCount = await Movement.countDocuments({
    type: 'TRANSFER',
    productId: product._id,
    warehouseId: BAKAARO,
    quantity: 3,
  });
  console.log('Total qty-3 movements:', movementCount, '(expect 1 for sequential)');

  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
