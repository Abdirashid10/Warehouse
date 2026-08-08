/**
 * @param {{ quantity: number, productName: string, fromName: string, toName: string, userReason?: string }}
 */
function formatTransferReason({ quantity, productName, fromName, toName, userReason = '' }) {
  const base = `Transferred ${quantity} ${productName} from ${fromName} to ${toName}`;
  const note = String(userReason || '').trim();
  return note ? `${base} — ${note}` : base;
}

module.exports = { formatTransferReason };
