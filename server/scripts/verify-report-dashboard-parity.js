/**
 * Assert the audit/PDF report and the dashboard report the SAME live numbers.
 *
 * Runs the real controllers against the real database and compares every
 * figure that appears both on the dashboard/mobile KPI strip and in the
 * generated PDF executive summary.
 *
 * Usage: node scripts/verify-report-dashboard-parity.js
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { connectDB } = require('../config/db');
const { getDashboardStats, getDashboardWidgets } = require('../controllers/dashboardController');
const { getInventoryAudit, getValuation } = require('../controllers/reportsController');
const { summarizeInventoryRows } = require('../utils/stockStatus');
const {
  summarizeInventoryFinancials,
  summarizeConditionBreakdown,
  summarizeWarehouseTotals,
} = require('../utils/inventoryValuation');

function mockRes() {
  const res = {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    },
  };
  return res;
}

async function call(handler, req = {}) {
  const res = mockRes();
  await handler(req, res);
  if (res.statusCode !== 200) {
    throw new Error(`handler failed (${res.statusCode}): ${res.body?.message}`);
  }
  return res.body;
}

const failures = [];

function check(label, actual, expected) {
  const ok = actual === expected;
  if (!ok) failures.push(`${label}: report=${actual} dashboard=${expected}`);
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${label.padEnd(42)} ${actual} vs ${expected}`);
}

/**
 * The live database will not always contain the states that used to break the
 * report (stock on a deleted product, one line split across conditions, a
 * zero-quantity line). Exercise them explicitly on the shared helpers.
 */
function verifyEdgeCases() {
  console.log('── Edge cases the old report got wrong ──');

  const rows = [
    // Split across conditions — the old report counted this as 3 lines.
    {
      warehouse_id: 'w1',
      warehouse_name: 'Alpha',
      current_quantity: 30,
      damaged_stock: 5,
      reserved_stock: 5,
      min_stock_threshold: 10,
      stock_status: 'In Stock',
      product: { unit_cost: 2, unit_price: 3 },
    },
    // Stock on a deleted product — the old report's inner join dropped these
    // units from total_units while the dashboard kept counting them.
    {
      warehouse_id: 'w1',
      warehouse_name: 'Alpha',
      current_quantity: 10,
      min_stock_threshold: 0,
      stock_status: 'In Stock',
      product: null,
    },
    // Zero-quantity line — the old warehouse rollup filtered it out.
    {
      warehouse_id: 'w2',
      warehouse_name: 'Beta',
      current_quantity: 0,
      min_stock_threshold: 5,
      stock_status: 'Out of Stock',
      product: { unit_cost: 4, unit_price: 9 },
    },
  ];

  const dashboard = summarizeInventoryRows(rows);
  const report = summarizeInventoryFinancials(rows);
  const condition = summarizeConditionBreakdown(rows);
  const warehouses = summarizeWarehouseTotals(rows);

  check('units incl. deleted-product stock', report.total_units, dashboard.total_units);
  check('lines are product x warehouse', report.inventory_lines, dashboard.total_lines);
  check('out of stock incl. zero-qty line', report.out_of_stock_lines, dashboard.out_of_stock);
  check('condition split totals units', condition.total_qty, report.total_units);
  check('good qty excludes damaged/insp.', condition.available_qty, 30);
  check('zero-qty warehouse still listed', warehouses.length, 2);
  check(
    'warehouse units sum to total',
    warehouses.reduce((s, w) => s + w.total_units, 0),
    report.total_units
  );
  check('cost value ignores null product', report.cost_value, 60);
  console.log('');
}

async function main() {
  verifyEdgeCases();

  await connectDB();

  const adminReq = {
    user: { id: 'script', username: 'parity-script', email: '', role: 'Admin' },
  };

  const [stats, widgets, audit, valuation] = [
    await call(getDashboardStats, adminReq),
    await call(getDashboardWidgets, adminReq),
    await call(getInventoryAudit, adminReq),
    await call(getValuation, adminReq),
  ];

  const fs = audit.financial_summary;
  const detail = audit.inventory_detail;

  console.log('\n── Dashboard KPI vs PDF executive summary ──');
  check('total units on hand', fs.total_units, stats.totalUnitsOnHand);
  check('inventory lines', fs.inventory_lines, stats.inventorySummary.total_lines);
  check('in stock lines', fs.in_stock_lines, stats.inStockLineCount);
  check('low stock lines', fs.low_stock_lines, stats.lowStockLineCount);
  check('out of stock lines', fs.out_of_stock_lines, stats.outOfStockLineCount);
  check('stock value (cost)', fs.cost_value, stats.totalStockValue);
  check('low stock (widgets alerts)', fs.low_stock_lines, widgets.alerts.lowStockCount);
  check('out of stock (widgets alerts)', fs.out_of_stock_lines, widgets.alerts.outOfStockCount);

  console.log('\n── Internal consistency of the report payload ──');
  check('detail rows == inventory_lines', detail.length, fs.inventory_lines);
  check(
    'Σ detail qty == total_units',
    detail.reduce((s, r) => s + r.current_quantity, 0),
    fs.total_units
  );
  check(
    'Σ detail line cost == cost_value',
    Math.round(detail.reduce((s, r) => s + r.line_cost_value, 0) * 100) / 100,
    fs.cost_value
  );
  check(
    'Σ detail line retail == retail_value',
    Math.round(detail.reduce((s, r) => s + r.line_retail_value, 0) * 100) / 100,
    fs.retail_value
  );
  check('condition total == total_units', audit.condition_breakdown.total_qty, fs.total_units);
  check(
    'Σ warehouse units == total_units',
    audit.warehouse_comparison.reduce((s, w) => s + w.total_units, 0),
    fs.total_units
  );
  check(
    'Σ warehouse lines == inventory_lines',
    audit.warehouse_comparison.reduce((s, w) => s + w.line_count, 0),
    fs.inventory_lines
  );
  check(
    'Σ warehouse cost == cost_value',
    Math.round(audit.warehouse_comparison.reduce((s, w) => s + w.cost_value, 0) * 100) / 100,
    fs.cost_value
  );
  check(
    'alert rows == low + out',
    audit.low_stock_alerts.length,
    fs.low_stock_lines + fs.out_of_stock_lines
  );
  check('inventory_summary mirrors units', audit.inventory_summary.total_units, fs.total_units);

  console.log('\n── Legacy /reports/valuation (mobile) ──');
  check('valuation total_units', valuation.valuation.total_units, fs.total_units);
  check('valuation inventory_lines', valuation.valuation.inventory_lines, fs.inventory_lines);

  console.log('\n── Warehouse rollup: dashboard widgets vs report ──');
  const reportByWarehouse = new Map(
    audit.warehouse_comparison.map((w) => [String(w.warehouse_id), w])
  );
  for (const w of widgets.warehouseStats) {
    const match = reportByWarehouse.get(String(w.id));
    check(`  ${w.name} units`, match?.total_units, w.totalUnits);
    check(`  ${w.name} lines`, match?.line_count, w.lineCount);
  }

  await mongoose.disconnect();

  if (failures.length) {
    console.error(`\n${failures.length} MISMATCH(ES):`);
    failures.forEach((f) => console.error(`  - ${f}`));
    process.exit(1);
  }
  console.log('\nAll dashboard / mobile / PDF figures match.');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
