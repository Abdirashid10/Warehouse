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

async function sumAvailable(productId, warehouseId) {
  const lines = await Inventory.find({ productId, warehouseId, condition: CONDITION }).lean();
  return lines.reduce((s, l) => s + (l.quantity || 0), 0);
}

async function postTransfer(token, productId, qty) {
  return fetch(`${BASE}/api/inventory/movements`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      type: 'TRANSFER',
      productId: String(productId),
      fromWarehouseId: BAKAARO,
      toWarehouseId: SUUQBACAAD,
      quantity: qty,
      reason: 'Double submit simulation test',
      condition: CONDITION,
      source_location: 'Bakaaro',
      destination_location: 'Suuqbacaad',
    }),
  });
}

async function main() {
  await connectDB();
  const token = signAccessToken({ sub: ADMIN_ID, role: 'Admin' });
  const product = await Product.findOne().lean();

  await Inventory.deleteMany({ productId: product._id, warehouseId: BAKAARO, condition: CONDITION });
  await Inventory.create({
    productId: product._id,
    warehouseId: BAKAARO,
    condition: CONDITION,
    quantity: 7,
    createdBy: ADMIN_ID,
  });

  console.log('Before double submit:', await sumAvailable(product._id, BAKAARO));

  const [r1, r2] = await Promise.all([
    postTransfer(token, product._id, 3),
    postTransfer(token, product._id, 3),
  ]);

  console.log('Response 1:', r1.status);
  console.log('Response 2:', r2.status);
  console.log('After double submit:', await sumAvailable(product._id, BAKAARO), '(expected 4 if single, 1 if double)');

  const movements = await Movement.countDocuments({
    type: 'TRANSFER',
    productId: product._id,
    warehouseId: BAKAARO,
    quantity: 3,
    createdAt: { $gte: new Date(Date.now() - 60000) },
  });
  console.log('Movements created in last minute:', movements);

  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
