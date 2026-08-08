const NOTES_MIN_LENGTH = 10;

export function validateMovementReason(reason) {
  const r = String(reason ?? '').trim();
  if (!r) {
    return 'Notes / reason is required.';
  }
  if (r.length < NOTES_MIN_LENGTH) {
    return 'Enter at least 10 characters.';
  }
  return null;
}

export const INSUFFICIENT_STOCK_DENIED =
  'Transaction Denied: Insufficient stock available in this warehouse.';

export function isReasonValidationError(message) {
  if (!message) return false;
  return message.includes('Notes / reason') || message.includes('Enter at least 10');
}
