/**
 * Signed quantity applied to inventory (+ inbound, − outbound, ± adjustment).
 * For TRANSFER, returns the actual transferred quantity (positive) since
 * delta is 0 by design (stock leaves one warehouse and enters another).
 */
function signedQuantityForMovement(movement) {
  const qty = movement.quantity ?? 0;

  if (movement.type === 'TRANSFER') {
    return qty;
  }

  if (movement.delta != null && Number.isFinite(movement.delta)) {
    return movement.delta;
  }

  if (movement.type === 'INBOUND' || movement.type === 'RETURN') return qty;
  if (movement.type === 'OUTBOUND') return -qty;
  return qty;
}

const { formatPerformedByUser } = require('./createdByDto');

function formatMovementResponse(movement) {
  const signed = signedQuantityForMovement(movement);
  const performed_by = formatPerformedByUser(movement, {
    missingMeansDeleted: Boolean(extractPerformerId(movement)),
  });

  return {
    ...movement,
    signed_quantity: signed,
    source_location: movement.source_location ?? '',
    destination_location: movement.destination_location ?? '',
    created_by: performed_by,
    performed_by,
  };
}

function extractPerformerId(movement) {
  if (!movement) return null;
  const fields = [movement.createdBy, movement.userId, movement.performer, movement.creator];
  for (const value of fields) {
    if (!value) continue;
    if (typeof value === 'object' && value._id) return value._id.toString();
    return String(value);
  }
  return null;
}

module.exports = { signedQuantityForMovement, formatMovementResponse };
