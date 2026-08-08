const NOTES_MIN_LENGTH = 10;

/**
 * Length-only notes validation for stock movements (no regex or content filters).
 * Returns error message or null if valid.
 */
function validateMovementReason(reason) {
  const r = String(reason ?? '').trim();
  if (!r) {
    return 'Notes / reason is required.';
  }
  if (r.length < NOTES_MIN_LENGTH) {
    return 'Enter at least 10 characters.';
  }
  return null;
}

module.exports = { validateMovementReason, NOTES_MIN_LENGTH };
