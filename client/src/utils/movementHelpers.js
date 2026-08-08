import { CONDITION_AVAILABLE } from './inventoryConditions';

export const INBOUND_SOURCE_LOCATION = 'External Vendor / Supplier';

export const EMPTY_MOVEMENT_FORM = {
  type: 'INBOUND',
  warehouseId: '',
  fromWarehouseId: '',
  toWarehouseId: '',
  quantity: 1,
  targetQuantity: '',
  reason: '',
  binLocation: '',
  condition: CONDITION_AVAILABLE,
  customerName: '',
  referenceNumber: '',
  batchNumber: '',
  manufactureDate: '',
  expiryDate: '',
};

/** Badge styles per movement type (type pill). */
export function movementTypeBadgeClass(type) {
  switch (type) {
    case 'INBOUND':
      return 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-500/20 dark:text-emerald-200 dark:ring-emerald-500/35';
    case 'OUTBOUND':
      return 'bg-red-50 text-red-700 ring-1 ring-red-200 dark:bg-red-500/20 dark:text-red-200 dark:ring-red-500/35';
    case 'ADJUSTMENT':
      return 'bg-amber-50 text-amber-800 ring-1 ring-amber-200 dark:bg-amber-500/20 dark:text-amber-200 dark:ring-amber-500/35';
    case 'TRANSFER':
      return 'bg-sky-50 text-sky-800 ring-1 ring-sky-200 dark:bg-sky-500/20 dark:text-sky-200 dark:ring-sky-500/35';
    case 'RETURN':
      return 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-500/20 dark:text-emerald-200 dark:ring-emerald-500/35';
    default:
      return 'bg-slate-100 text-slate-600 ring-1 ring-slate-200 dark:bg-slate-700 dark:text-slate-300 dark:ring-slate-600';
  }
}

/** High-contrast quantity pill (matches type colors). */
export function movementQuantityBadgeClass(type, signed) {
  if (type === 'TRANSFER') {
    return 'bg-sky-50 text-sky-800 ring-1 ring-sky-200 dark:bg-sky-500/20 dark:text-sky-200 dark:ring-sky-500/35';
  }
  if (type === 'INBOUND' || type === 'RETURN' || signed > 0) {
    return 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-500/20 dark:text-emerald-200 dark:ring-emerald-500/35';
  }
  if (type === 'OUTBOUND' || signed < 0) {
    return 'bg-red-50 text-red-700 ring-1 ring-red-200 dark:bg-red-500/20 dark:text-red-200 dark:ring-red-500/35';
  }
  if (type === 'ADJUSTMENT') {
    return 'bg-amber-50 text-amber-800 ring-1 ring-amber-200 dark:bg-amber-500/20 dark:text-amber-200 dark:ring-amber-500/35';
  }
  return 'bg-slate-100 text-slate-600 ring-1 ring-slate-200 dark:bg-slate-700 dark:text-slate-300 dark:ring-slate-600';
}

/**
 * Resolve the display quantity for a movement.
 * TRANSFER uses the raw quantity (positive) since delta is 0 by design.
 */
export function resolveSignedQuantity(movement) {
  const qty = Number(movement?.quantity) || 0;

  if (movement?.type === 'TRANSFER') {
    return qty;
  }

  if (movement?.signed_quantity != null && Number.isFinite(movement.signed_quantity) && movement.signed_quantity !== 0) {
    return movement.signed_quantity;
  }
  if (movement?.delta != null && Number.isFinite(movement.delta)) {
    return movement.delta;
  }

  if (movement?.type === 'INBOUND' || movement?.type === 'RETURN') return qty;
  if (movement?.type === 'OUTBOUND') return -qty;
  return qty;
}

export function formatSignedQuantity(movement) {
  const signed = resolveSignedQuantity(movement);
  if (movement?.type === 'TRANSFER') {
    return signed > 0 ? `↔ ${signed}` : '0';
  }
  if (signed > 0) return `+${signed}`;
  if (signed < 0) return String(signed);
  return '0';
}

function warehouseName(movement, field) {
  const wh = movement?.[field];
  if (!wh) return '';
  if (typeof wh === 'string') return wh;
  return wh.name || '';
}

export function movementFromLocation(movement) {
  const source = String(movement?.source_location || '').trim();
  if (source) return source;

  if (movement?.type === 'INBOUND' || movement?.type === 'RETURN') {
    return INBOUND_SOURCE_LOCATION;
  }

  if (movement?.type === 'TRANSFER') {
    return (
      warehouseName(movement, 'from_warehouse') ||
      warehouseName(movement, 'warehouse') ||
      '—'
    );
  }

  return warehouseName(movement, 'warehouse') || '—';
}

export function movementToLocation(movement) {
  const dest = String(movement?.destination_location || '').trim();
  if (dest) return dest;

  if (movement?.type === 'TRANSFER') {
    return warehouseName(movement, 'to_warehouse') || '—';
  }

  if (movement?.type === 'OUTBOUND') {
    return dest || 'Customer';
  }

  return warehouseName(movement, 'warehouse') || '—';
}

export function formatMovementWarehouse(movement) {
  if (movement?.type === 'TRANSFER') {
    return `${movementFromLocation(movement)} → ${movementToLocation(movement)}`;
  }
  return movementToLocation(movement) || movementFromLocation(movement) || '—';
}

export function formatOutboundReason(referenceNumber, destination) {
  const ref = String(referenceNumber || '').trim();
  const dest = String(destination || '').trim();
  const orderRef = ref.startsWith('#') ? ref.slice(1) : ref;
  return `[OUTBOUND] Order #${orderRef} - Shipped to ${dest}`;
}

export function formatTransferReason(quantity, productName, fromName, toName, userReason = '') {
  const base = `Transferred ${quantity} ${productName} from ${fromName} to ${toName}`;
  const note = String(userReason || '').trim();
  return note ? `${base} — ${note}` : base;
}
