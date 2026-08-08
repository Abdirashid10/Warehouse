/**
 * Enterprise WMS outbound reason line stored on Movement.reason.
 * @param {string} referenceNumber e.g. SO-1024
 * @param {string} destination e.g. Acme Retail — Chicago
 */
function formatOutboundReason(referenceNumber, destination) {
  const ref = String(referenceNumber || '').trim();
  const dest = String(destination || '').trim();
  const orderRef = ref.startsWith('#') ? ref.slice(1) : ref;
  return `[OUTBOUND] Order #${orderRef} - Shipped to ${dest}`;
}

module.exports = { formatOutboundReason };
