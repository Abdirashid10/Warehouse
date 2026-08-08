const ORDER_STATUSES = ['Pending', 'Processing', 'Packed', 'Shipped', 'Delivered'];

const STATUS_FLOW = {
  Pending: 'Processing',
  Processing: 'Packed',
  Packed: 'Shipped',
  Shipped: 'Delivered',
  Delivered: null,
};

function getNextStatus(current) {
  return STATUS_FLOW[current] ?? null;
}

function canTransition(from, to) {
  if (!ORDER_STATUSES.includes(from) || !ORDER_STATUSES.includes(to)) return false;
  if (from === to) return false;
  let cursor = from;
  while (cursor && cursor !== to) {
    cursor = STATUS_FLOW[cursor];
    if (!cursor) return false;
  }
  return cursor === to || STATUS_FLOW[from] === to;
}

/** Allow forward steps only (one or more steps ahead in the chain). */
function isValidStatusTransition(from, to) {
  if (from === to) return false;
  let cursor = from;
  while (cursor) {
    cursor = STATUS_FLOW[cursor];
    if (cursor === to) return true;
  }
  return false;
}

module.exports = {
  ORDER_STATUSES,
  STATUS_FLOW,
  getNextStatus,
  isValidStatusTransition,
};
