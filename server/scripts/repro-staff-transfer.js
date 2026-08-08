require('dotenv').config();
const { signAccessToken } = require('../utils/jwt');

const BASE = 'http://localhost:5000';
const MUSE_ID = '6a0dda6bf8cd88d7f2a2bce9';
const BAKAARO = '6a070962aaefe07a1e2cba07';
const SUUQBACAAD = '6a073750fd10f353fc03b320';
const PRODUCT = '6a07371bfd10f353fc03b312';

async function main() {
  const token = signAccessToken({ sub: MUSE_ID, role: 'Staff' });

  const payload = {
    type: 'TRANSFER',
    productId: PRODUCT,
    fromWarehouseId: BAKAARO,
    toWarehouseId: SUUQBACAAD,
    quantity: 4,
    reason: '',
    condition: 'Available / Good',
    source_location: 'Bakaaro',
    destination_location: 'Suuqbacaad',
  };

  console.log('=== REQUEST ===');
  console.log('POST /api/inventory/movements');
  console.log('Authorization: Bearer <Muse Staff token>');
  console.log('Body:', JSON.stringify(payload, null, 2));

  const res = await fetch(`${BASE}/api/inventory/movements`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  const text = await res.text();
  console.log('\n=== RESPONSE ===');
  console.log('Status:', res.status, res.statusText);
  try {
    console.log('Body:', JSON.stringify(JSON.parse(text), null, 2));
  } catch {
    console.log('Body:', text);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
