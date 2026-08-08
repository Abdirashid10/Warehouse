const { INBOUND_SOURCE_LOCATION } = require('../constants/movementLocations');

/**
 * Resolves double-entry routing labels for a movement record.
 */
function buildMovementRouting({
  type,
  warehouseName = '',
  fromWarehouseName = '',
  toWarehouseName = '',
  customerName = '',
  destinationLocation = '',
}) {
  const wh = String(warehouseName || '').trim();
  const customer = String(customerName || destinationLocation || '').trim();

  switch (type) {
    case 'INBOUND':
    case 'RETURN':
      return {
        source_location: INBOUND_SOURCE_LOCATION,
        destination_location: wh,
      };
    case 'OUTBOUND':
      return {
        source_location: wh,
        destination_location: customer,
      };
    case 'TRANSFER':
      return {
        source_location: String(fromWarehouseName || '').trim(),
        destination_location: String(toWarehouseName || '').trim(),
      };
    case 'ADJUSTMENT':
      return {
        source_location: wh,
        destination_location: wh,
      };
    default:
      return { source_location: '', destination_location: '' };
  }
}

module.exports = { buildMovementRouting, INBOUND_SOURCE_LOCATION };
