import { expiryBadgeConfig } from '../utils/expiryStatus';

export function ExpiryStatusBadge({ status }) {
  const { label, className } = expiryBadgeConfig(status);
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold ${className}`}
    >
      {label}
    </span>
  );
}
