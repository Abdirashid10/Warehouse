/**
 * Smart due-date helper.
 *
 * Compares two spans and reports whichever matters for the UI:
 *  - `windowHours`   — created_at → due_date, the runway the assignee was originally given.
 *    A task created with a sub-24h window is flagged `isTightWindow` so supervisors can see
 *    the deadline was tight from the start, not just close now.
 *  - `hoursRemaining` — now → due_date, what is actually left. This drives the badge.
 *
 * Closed tasks (Completed / Rejected) never report urgency — a finished task is not late.
 */

const HOUR_MS = 3_600_000;
const URGENT_HOURS = 24;
const CRITICAL_HOURS = 6;

const CLOSED_STATUSES = ['Completed', 'Rejected'];

function toDate(value) {
  if (!value) return null;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
}

/** "3h 20m", "45m", "2d 4h" — coarse, human, no seconds. */
export function formatGap(ms) {
  const minutes = Math.max(0, Math.round(Math.abs(ms) / 60000));
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) {
    const rem = minutes % 60;
    return rem ? `${hours}h ${rem}m` : `${hours}h`;
  }
  const days = Math.floor(hours / 24);
  const rem = hours % 24;
  return rem ? `${days}d ${rem}h` : `${days}d`;
}

function sameCalendarDay(a, b) {
  return a.getFullYear() === b.getFullYear()
    && a.getMonth() === b.getMonth()
    && a.getDate() === b.getDate();
}

function isNextCalendarDay(due, now) {
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  return sameCalendarDay(due, tomorrow);
}

/**
 * @returns {{
 *   state: 'none'|'closed'|'overdue'|'critical'|'urgent'|'upcoming',
 *   tone: 'red'|'amber'|'muted',
 *   label: string,
 *   isUrgent: boolean,
 *   hoursRemaining: number|null,
 *   windowHours: number|null,
 *   isTightWindow: boolean,
 *   dueDate: Date|null,
 * }}
 */
export function dueDateInfo(task, now = new Date()) {
  const base = {
    state: 'none',
    tone: 'muted',
    label: '',
    isUrgent: false,
    hoursRemaining: null,
    windowHours: null,
    isTightWindow: false,
    dueDate: null,
  };

  const due = toDate(task?.due_date ?? task?.dueDate);
  if (!due) return base;

  const created = toDate(task?.created_at ?? task?.createdAt);
  const windowHours = created ? (due - created) / HOUR_MS : null;
  const hoursRemaining = (due - now) / HOUR_MS;

  const common = {
    ...base,
    dueDate: due,
    hoursRemaining,
    windowHours,
    isTightWindow: windowHours != null && windowHours > 0 && windowHours <= URGENT_HOURS,
  };

  if (CLOSED_STATUSES.includes(task?.status)) {
    return { ...common, state: 'closed' };
  }

  if (hoursRemaining < 0) {
    return {
      ...common,
      state: 'overdue',
      tone: 'red',
      isUrgent: true,
      label: `Overdue by ${formatGap(due - now)}`,
    };
  }

  if (hoursRemaining <= URGENT_HOURS) {
    const left = formatGap(due - now);
    const label = sameCalendarDay(due, now)
      ? `Due today · ${left} left`
      : isNextCalendarDay(due, now)
        ? `Due tomorrow · ${left} left`
        : `Due in ${left}`;

    return {
      ...common,
      state: hoursRemaining <= CRITICAL_HOURS ? 'critical' : 'urgent',
      tone: hoursRemaining <= CRITICAL_HOURS ? 'red' : 'amber',
      isUrgent: true,
      label,
    };
  }

  return { ...common, state: 'upcoming', label: `Due in ${formatGap(due - now)}` };
}

/** True when the deadline needs a visual warning (overdue or inside the 24h window). */
export function isDueSoon(task, now = new Date()) {
  return dueDateInfo(task, now).isUrgent;
}
