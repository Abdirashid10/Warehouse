export const CONDITION_AVAILABLE = 'Available / Good';
export const CONDITION_DAMAGED = 'Damaged / Defective';
export const CONDITION_INSPECTION = 'Under Inspection';

export const INVENTORY_CONDITIONS = [
  CONDITION_AVAILABLE,
  CONDITION_DAMAGED,
  CONDITION_INSPECTION,
];

export function normalizeCondition(value) {
  const v = String(value ?? '').trim();
  if (INVENTORY_CONDITIONS.includes(v)) return v;
  return CONDITION_AVAILABLE;
}

export function isOutboundAllowed(condition) {
  return normalizeCondition(condition) === CONDITION_AVAILABLE;
}

export const OUTBOUND_CONDITION_DENIED =
  'Action Denied: Cannot ship items that are damaged or under inspection.';

export function conditionBadgeClass(condition) {
  const c = normalizeCondition(condition);
  if (c === CONDITION_AVAILABLE) {
    return 'bg-emerald-100 text-emerald-800 ring-1 ring-emerald-300 dark:bg-emerald-500/25 dark:text-emerald-200 dark:ring-emerald-500/40';
  }
  if (c === CONDITION_DAMAGED) {
    return 'bg-red-100 text-red-800 ring-1 ring-red-300 dark:bg-red-500/25 dark:text-red-200 dark:ring-red-500/40';
  }
  return 'bg-amber-100 text-amber-900 ring-1 ring-amber-300 dark:bg-amber-500/25 dark:text-amber-200 dark:ring-amber-500/40';
}
