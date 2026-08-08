import { movementTypeBadgeClass } from '../utils/movementHelpers';

export function MovementTypeBadge({ type }) {
  return (
    <span className={`wms-badge ${movementTypeBadgeClass(type)}`}>{type}</span>
  );
}
