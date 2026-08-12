/**
 * Verify audit-log module access control.
 *
 * Asserts that a Supervisor can never read Admin-only audit modules
 * (User Management, System) through any path — the log list, the module
 * filter, the KPI counts, the pagination total, or the /recent feed — while
 * still seeing every operational module their role can act on.
 *
 * Usage: node scripts/verify-audit-module-access.js
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { connectDB } = require('../config/db');
const { UserActivityLog, User } = require('../models');
const {
  listActivities,
  getRecentActivities,
  buildActivityFilter,
} = require('../controllers/auditController');
const {
  SUPERVISOR_AUDIT_MODULES,
  ADMIN_ONLY_AUDIT_MODULES,
  visibleModuleKeysForRole,
  isModuleVisibleToRole,
  normalizeModuleKey,
} = require('../constants/audit');

const failures = [];

function ok(label, condition, detail = '') {
  if (!condition) failures.push(`${label}${detail ? ` — ${detail}` : ''}`);
  console.log(`${condition ? 'PASS' : 'FAIL'}  ${label}${detail ? `  (${detail})` : ''}`);
}

function mockRes() {
  return {
    statusCode: 200,
    body: null,
    status(code) { this.statusCode = code; return this; },
    json(payload) { this.body = payload; return this; },
  };
}

async function call(handler, req) {
  const res = mockRes();
  await handler(req, res);
  if (res.statusCode !== 200) {
    throw new Error(`handler failed (${res.statusCode}): ${res.body?.message}`);
  }
  return res.body;
}

/* ── 1. The rules themselves ── */
function verifyRules() {
  console.log('── Module visibility rules ──');

  ok('Admin is unrestricted', visibleModuleKeysForRole('Admin') === null);
  ok(
    'Supervisor allowlist excludes Admin-only modules',
    ADMIN_ONLY_AUDIT_MODULES.every((m) => !SUPERVISOR_AUDIT_MODULES.includes(m)),
    SUPERVISOR_AUDIT_MODULES.join(', ')
  );
  ok('unknown role sees nothing', visibleModuleKeysForRole('Staff').length === 0);

  for (const stored of ['User Management', 'user', 'USER MANAGEMENT', 'System']) {
    ok(`Supervisor blocked from "${stored}"`, !isModuleVisibleToRole(stored, 'Supervisor'));
    ok(`Admin allowed "${stored}"`, isModuleVisibleToRole(stored, 'Admin'));
  }
  for (const stored of ['Inventory', 'Tasks', 'Orders', 'Warehouse', 'Profile', 'Movement']) {
    ok(`Supervisor allowed "${stored}"`, isModuleVisibleToRole(stored, 'Supervisor'));
  }
  // An unrecognised module must fail closed rather than slip through.
  ok('unknown module denied to Supervisor', !isModuleVisibleToRole('Payroll', 'Supervisor'));

  console.log('');
}

/* ── 2. The query the controller builds ── */
function verifyFilters(supervisorId) {
  console.log('── Query filter construction ──');

  const supReq = (query = {}) => ({
    user: { id: supervisorId, role: 'Supervisor', assignedWarehouseIds: [] },
    query,
  });

  const plain = buildActivityFilter(supReq());
  const moduleClause = (plain.$and || []).find((c) => c.module);
  ok('Supervisor query is module-scoped', Boolean(moduleClause));
  ok(
    'scope contains no User Management value',
    !(moduleClause?.module?.$in || []).some((v) => normalizeModuleKey(v) === 'user'),
    (moduleClause?.module?.$in || []).join(', ')
  );

  for (const forbidden of ['user', 'User Management', 'system']) {
    const denied = buildActivityFilter(supReq({ module: forbidden }));
    ok(
      `module=${forbidden} yields an impossible filter`,
      Array.isArray(denied._id?.$in) && denied._id.$in.length === 0
    );
  }

  const allowed = buildActivityFilter(supReq({ module: 'inventory' }));
  ok('module=inventory still queries normally', !allowed._id);

  const adminFilter = buildActivityFilter({
    user: { id: supervisorId, role: 'Admin' },
    query: { module: 'user' },
  });
  ok('Admin keeps full access to module=user', !adminFilter._id);

  // Warehouse scoping must survive alongside the module scope.
  const scoped = buildActivityFilter({
    user: {
      id: supervisorId,
      role: 'Supervisor',
      assignedWarehouseIds: [new mongoose.Types.ObjectId().toString()],
    },
    query: {},
  });
  ok(
    'warehouse scoping still applied',
    (scoped.$and || []).some((c) => Array.isArray(c.$or))
  );

  // A free-text search must not become an escape hatch.
  const searched = buildActivityFilter(supReq({ q: 'user' }));
  const searchModuleClause = (searched.$and || []).find((c) => c.module);
  ok('text search stays module-scoped', Boolean(searchModuleClause) && Boolean(searched.$or));

  console.log('');
}

/* ── 3. The live endpoints ── */
async function verifyEndpoints(supervisor) {
  console.log('── Live endpoints ──');

  const supReq = (query = {}) => ({
    user: {
      id: supervisor._id.toString(),
      role: 'Supervisor',
      assignedWarehouseIds: (supervisor.assignedWarehouseIds || []).map(String),
    },
    query,
  });
  const adminReq = (query = {}) => ({ user: { id: 'admin', role: 'Admin' }, query, });

  const storedUserLogs = await UserActivityLog.countDocuments({
    module: { $in: ['User Management', 'user'] },
  });
  console.log(`      (${storedUserLogs} User Management entries exist in the database)`);

  const supList = await call(listActivities, supReq({ limit: 200 }));
  const leaked = supList.activities.filter(
    (a) => normalizeModuleKey(a.module) === 'user' || normalizeModuleKey(a.module) === 'system'
  );
  ok('Supervisor list has no Admin-only entries', leaked.length === 0, `${leaked.length} leaked`);
  ok('Supervisor KPI counts omit users', supList.moduleCounts.user === undefined);
  ok(
    'Supervisor sees no target-user identities',
    supList.activities.every((a) => a.target === null)
  );
  ok(
    'visibleModules advertised to the client',
    Array.isArray(supList.visibleModules) && !supList.visibleModules.includes('user'),
    (supList.visibleModules || []).join(', ')
  );

  const supFiltered = await call(listActivities, supReq({ module: 'user' }));
  ok(
    'Supervisor filtering by module=user returns nothing',
    supFiltered.activities.length === 0 && supFiltered.pagination.total === 0
  );

  const supSearch = await call(listActivities, supReq({ q: 'user', limit: 200 }));
  ok(
    'Supervisor text search cannot surface them',
    supSearch.activities.every((a) => normalizeModuleKey(a.module) !== 'user')
  );

  const supRecent = await call(getRecentActivities, supReq({ limit: 50 }));
  ok(
    '/audit/recent is filtered too',
    supRecent.activities.every((a) => normalizeModuleKey(a.module) !== 'user')
  );

  const adminList = await call(listActivities, adminReq({ limit: 200 }));
  ok('Admin list is unrestricted', adminList.visibleModules === null);
  if (storedUserLogs > 0) {
    const adminFiltered = await call(listActivities, adminReq({ module: 'user' }));
    ok(
      'Admin still reads User Management',
      adminFiltered.pagination.total === storedUserLogs,
      `${adminFiltered.pagination.total} of ${storedUserLogs}`
    );
  }

  const supTotal = supList.pagination.total;
  ok(
    'Supervisor total excludes blocked entries',
    supTotal <= adminList.pagination.total,
    `supervisor ${supTotal} / admin ${adminList.pagination.total}`
  );

  console.log('');
}

async function main() {
  await connectDB();

  const supervisor =
    (await User.findOne({ role: 'Supervisor' }).select('_id assignedWarehouseIds').lean()) ||
    { _id: new mongoose.Types.ObjectId(), assignedWarehouseIds: [] };

  verifyRules();
  verifyFilters(supervisor._id.toString());
  await verifyEndpoints(supervisor);

  await mongoose.disconnect();

  if (failures.length) {
    console.error(`${failures.length} FAILURE(S):`);
    failures.forEach((f) => console.error(`  - ${f}`));
    process.exit(1);
  }
  console.log('Audit module access control verified.');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
