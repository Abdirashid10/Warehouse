import { conditionBadgeClass, normalizeCondition } from '../utils/inventoryConditions';

export function ConditionBadge({ condition }) {
  const label = normalizeCondition(condition);
  return (
    <span
      className={`inline-flex items-center rounded-md px-2 py-0.5 text-xs font-medium ${conditionBadgeClass(label)}`}
    >
      {label}
    </span>
  );
}
