import {
  formatSignedQuantity,
  movementQuantityBadgeClass,
  resolveSignedQuantity,
} from '../utils/movementHelpers';

export function MovementQuantityCell({ movement }) {
  const signed = resolveSignedQuantity(movement);
  const display = formatSignedQuantity(movement);

  return (
    <span
      className={`wms-badge inline-flex min-w-[2.75rem] justify-center font-mono tabular-nums ${movementQuantityBadgeClass(
        movement.type,
        signed
      )}`}
    >
      {display}
    </span>
  );
}
