const CONDITION_AVAILABLE = 'Available / Good';
const CONDITION_DAMAGED = 'Damaged / Defective';
const CONDITION_INSPECTION = 'Under Inspection';

const INVENTORY_CONDITIONS = [
  CONDITION_AVAILABLE,
  CONDITION_DAMAGED,
  CONDITION_INSPECTION,
];

function normalizeCondition(value) {
  const v = String(value ?? '').trim();
  if (INVENTORY_CONDITIONS.includes(v)) return v;
  return CONDITION_AVAILABLE;
}

function isOutboundAllowed(condition) {
  return normalizeCondition(condition) === CONDITION_AVAILABLE;
}

function validateConditionRequired(condition) {
  const c = String(condition ?? '').trim();
  if (!INVENTORY_CONDITIONS.includes(c)) {
    throw Object.assign(
      new Error(`condition must be one of: ${INVENTORY_CONDITIONS.join(', ')}`),
      { status: 400 }
    );
  }
  return c;
}

const OUTBOUND_CONDITION_DENIED =
  'Action Denied: Cannot ship items that are damaged or under inspection.';

function assertOutboundAllowed(condition) {
  const c = normalizeCondition(condition);
  if (!isOutboundAllowed(c)) {
    throw Object.assign(new Error(OUTBOUND_CONDITION_DENIED), {
      status: 400,
      code: 'CONDITION_NOT_SHIPPABLE',
      condition: c,
    });
  }
  return c;
}

module.exports = {
  CONDITION_AVAILABLE,
  CONDITION_DAMAGED,
  CONDITION_INSPECTION,
  INVENTORY_CONDITIONS,
  OUTBOUND_CONDITION_DENIED,
  normalizeCondition,
  isOutboundAllowed,
  validateConditionRequired,
  assertOutboundAllowed,
};
