/**
 * Verify task KPI consistency against live MongoDB.
 * Usage: node scripts/verifyTaskStats.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Task = require('../models/Task');
const { formatTask } = require('../utils/taskDto');
const { summarizeTaskStats, isTaskOverdue, workflowBucket } = require('../utils/taskStats');

async function rawStatusAgg() {
  return Task.aggregate([{ $group: { _id: '$status', count: { $sum: 1 } } }]);
}

async function legacyOverdueCount() {
  return Task.countDocuments({ status: 'Overdue' });
}

async function legacyDueDateOverdue() {
  const now = new Date();
  return Task.countDocuments({
    status: { $nin: ['Completed', 'Rejected'] },
    dueDate: { $lt: now },
  });
}

async function main() {
  const uri = process.env.MONGODB_URI || process.env.MONGO_URI;
  if (!uri) {
    console.error('MONGODB_URI not set');
    process.exit(1);
  }

  await mongoose.connect(uri);

  const rows = await Task.find({}).lean();
  const formatted = rows.map(formatTask);
  const stats = summarizeTaskStats(formatted);

  const rawAgg = await rawStatusAgg();
  const rawByStatus = Object.fromEntries(rawAgg.map((r) => [r._id || 'null', r.count]));
  const storedOverdue = await legacyOverdueCount();
  const dueDateOverdue = await legacyDueDateOverdue();

  console.log('\n=== BEFORE (legacy DB aggregation) ===');
  console.log('Raw status counts:', rawByStatus);
  console.log('Stored status=Overdue:', storedOverdue);
  console.log('Due date overdue (non-completed/rejected):', dueDateOverdue);

  console.log('\n=== AFTER (canonical KPI formulas) ===');
  console.log(JSON.stringify(stats, null, 2));

  console.log('\n=== Per-task workflow buckets ===');
  for (const t of formatted) {
    console.log(
      `- ${t.id?.slice(-6) || '?'} | stored=${t.status} | workflow=${t.workflow_status} | overdue=${t.is_overdue} | due=${t.due_date}`
    );
  }

  const mismatches = [];
  if (stats.overdue !== dueDateOverdue) {
    mismatches.push(`overdue KPI (${stats.overdue}) != due-date query (${dueDateOverdue})`);
  }
  if (storedOverdue > 0 && stats.awaiting + stats.accepted + stats.inProgress < stats.total) {
    mismatches.push(`${storedOverdue} tasks still stored as Overdue — recovered via workflowBucket`);
  }

  console.log('\n=== Consistency ===');
  if (mismatches.length === 0) {
    console.log('All KPI checks passed.');
  } else {
    console.log('Notes:');
    mismatches.forEach((m) => console.log(` - ${m}`));
  }

  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
