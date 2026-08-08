/**
 * Compare raw vs normalized module aggregation for audit KPI cards.
 * Usage: node scripts/verify-audit-kpi-counts.js
 */
require('dotenv').config();
const { connectDB } = require('../config/db');
const { UserActivityLog } = require('../models');
const { normalizeModuleKey } = require('../constants/audit');

async function main() {
  await connectDB();

  const rawAgg = await UserActivityLog.aggregate([
    { $group: { _id: '$module', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);

  const before = {};
  const after = {};
  for (const row of rawAgg) {
    if (!row._id) continue;
    before[row._id] = row.count;
    const key = normalizeModuleKey(row._id);
    if (key) after[key] = (after[key] || 0) + row.count;
  }

  const total = await UserActivityLog.countDocuments();

  console.log('Total log records:', total);
  console.log('\nBEFORE (raw DB module keys — KPI cards read lowercase aliases):');
  console.log(JSON.stringify(before, null, 2));
  console.log('\nAFTER (normalized keys — matches KPI cards):');
  console.log(JSON.stringify(after, null, 2));

  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
