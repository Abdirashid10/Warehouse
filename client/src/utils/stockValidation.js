import {
  CONDITION_AVAILABLE,
  CONDITION_DAMAGED,
  CONDITION_INSPECTION,
  normalizeCondition,
} from './inventoryConditions';

export function formatInsufficientStockMessage(availableQuantity) {
  const available = Number(availableQuantity) || 0;
  return `Insufficient stock. Available quantity: ${available}`;
}

export function getAvailableForCondition(availabilityRow, condition) {
  if (!availabilityRow) return 0;
  const c = normalizeCondition(condition);
  if (c === CONDITION_AVAILABLE) {
    return availabilityRow.available ?? availabilityRow.availableQuantity ?? 0;
  }
  if (c === CONDITION_DAMAGED) {
    return availabilityRow.damaged ?? 0;
  }
  if (c === CONDITION_INSPECTION) {
    return availabilityRow.inspection ?? 0;
  }
  return availabilityRow.available ?? availabilityRow.availableQuantity ?? 0;
}

export function validateTransferQuantity({
  quantity,
  availableQuantity,
  fromWarehouseId,
  toWarehouseId,
}) {
  const qty = parseInt(String(quantity), 10);

  if (!Number.isFinite(qty) || qty <= 0) {
    return { valid: false, error: 'Quantity must be a positive integer' };
  }

  if (!fromWarehouseId || !toWarehouseId) {
    return { valid: false, error: 'Select source and destination warehouses' };
  }

  if (String(fromWarehouseId) === String(toWarehouseId)) {
    return { valid: false, error: 'Source and destination warehouses must be different' };
  }

  const available = Number(availableQuantity) || 0;

  if (available <= 0) {
    return {
      valid: false,
      error: 'No inventory record found for this product at the source warehouse',
    };
  }

  if (qty > available) {
    return { valid: false, error: formatInsufficientStockMessage(available) };
  }

  return { valid: true, quantity: qty, availableQuantity: available };
}
