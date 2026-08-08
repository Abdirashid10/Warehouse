/**
 * Client-side mirror of server/utils/taskStats.js — keep formulas in sync.
 */

export function isTaskOverdue(task, now = new Date()) {
  if (!task) return false;
  const status = task.status;
  if (status === 'Completed' || status === 'Rejected') return false;

  const dueRaw = task.due_date ?? task.dueDate;
  if (!dueRaw) return false;

  const due = new Date(dueRaw);
  if (Number.isNaN(due.getTime())) return false;

  return due < now;
}

export function workflowBucket(task) {
  const status = task?.status;
  if (status !== 'Overdue') return status;

  const history = task.status_history || task.statusHistory || [];
  for (let i = history.length - 1; i >= 0; i -= 1) {
    const entry = history[i];
    if (entry?.status && entry.status !== 'Overdue') {
      return entry.status;
    }
  }
  return 'Pending';
}

function bucketToKpiKey(bucket) {
  if (bucket === 'Pending') return 'awaiting';
  if (bucket === 'Accepted') return 'accepted';
  if (bucket === 'In Progress' || bucket === 'Waiting Confirmation') return 'inProgress';
  if (bucket === 'Completed') return 'completed';
  if (bucket === 'Rejected') return 'rejected';
  return null;
}

export function summarizeTaskStats(taskList, now = new Date()) {
  const stats = {
    total: 0,
    awaiting: 0,
    accepted: 0,
    inProgress: 0,
    completed: 0,
    rejected: 0,
    overdue: 0,
    Pending: 0,
    Accepted: 0,
    'In Progress': 0,
    'Waiting Confirmation': 0,
    Completed: 0,
    Rejected: 0,
    Overdue: 0,
  };

  if (!Array.isArray(taskList)) {
    return { ...stats, _total: 0 };
  }

  for (const task of taskList) {
    stats.total += 1;
    const bucket = workflowBucket(task);
    const kpiKey = bucketToKpiKey(bucket);

    if (kpiKey) stats[kpiKey] += 1;

    if (bucket === 'Pending') stats.Pending += 1;
    else if (bucket === 'Accepted') stats.Accepted += 1;
    else if (bucket === 'In Progress') stats['In Progress'] += 1;
    else if (bucket === 'Waiting Confirmation') stats['Waiting Confirmation'] += 1;
    else if (bucket === 'Completed') stats.Completed += 1;
    else if (bucket === 'Rejected') stats.Rejected += 1;

    if (isTaskOverdue(task, now)) {
      stats.overdue += 1;
      stats.Overdue += 1;
    }
  }

  stats['In Progress'] = stats.inProgress;
  stats.Pending = stats.awaiting;
  stats.Accepted = stats.accepted;
  stats.Completed = stats.completed;
  stats.Rejected = stats.rejected;

  stats._total = stats.total;
  return stats;
}

export function filterTasksByStatus(taskList, statusFilter, now = new Date()) {
  if (!Array.isArray(taskList)) return [];
  if (!statusFilter) return taskList;

  if (statusFilter === 'Overdue') {
    return taskList.filter((t) => isTaskOverdue(t, now));
  }
  if (statusFilter === 'In Progress') {
    return taskList.filter((t) =>
      ['In Progress', 'Waiting Confirmation'].includes(workflowBucket(t))
    );
  }
  if (statusFilter === 'Pending') {
    return taskList.filter((t) => workflowBucket(t) === 'Pending');
  }
  return taskList.filter((t) => workflowBucket(t) === statusFilter);
}

/** Prefer API workflow_status; falls back to stored status. */
export function taskWorkflowStatus(task) {
  return task?.workflow_status || task?.status;
}

/** Prefer API stats; recompute from list when missing (e.g. cached offline). */
export function resolveTaskStats(tasks, apiStats) {
  if (apiStats && typeof apiStats.total === 'number') {
    return {
      ...summarizeTaskStats([]),
      ...apiStats,
      _total: apiStats.total,
      Pending: apiStats.awaiting ?? apiStats.Pending ?? 0,
      Accepted: apiStats.accepted ?? apiStats.Accepted ?? 0,
      'In Progress': apiStats.inProgress ?? apiStats['In Progress'] ?? 0,
      Completed: apiStats.completed ?? apiStats.Completed ?? 0,
      Rejected: apiStats.rejected ?? apiStats.Rejected ?? 0,
      Overdue: apiStats.overdue ?? apiStats.Overdue ?? 0,
    };
  }
  return summarizeTaskStats(tasks);
}
