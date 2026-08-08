import { orderStatusBadgeClass } from '../utils/orderHelpers';

export function OrderStatusBadge({ status }) {
  return (
    <span
      className={`inline-flex rounded-md px-2.5 py-1 text-xs font-semibold ${orderStatusBadgeClass(status)}`}
    >
      {status}
    </span>
  );
}
