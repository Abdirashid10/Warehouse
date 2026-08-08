import { cn } from '../../lib/utils';

const ACCENT_CLASS = {
  sky: 'wms-kpi-card--sky',
  emerald: 'wms-kpi-card--emerald',
  amber: 'wms-kpi-card--amber',
  red: 'wms-kpi-card--red',
};

export function KpiCard({ label, value, sub, accent = 'sky', trend, compact = false }) {
  const accentClass = ACCENT_CLASS[accent] || ACCENT_CLASS.sky;

  return (
    <div
      className={cn('wms-kpi-card', accentClass, compact ? 'px-4 py-3' : 'px-5 py-4')}
    >
      <p className={cn('wms-kpi-card__label', compact ? 'text-[10px]' : 'text-[11px]')}>{label}</p>
      <p className={cn('wms-kpi-card__value', compact ? 'mt-1 text-xl' : 'mt-2 text-2xl')}>
        {value}
      </p>
      {sub ? <p className="mt-0.5 text-xs text-muted-foreground">{sub}</p> : null}
      {trend ? (
        <p className="mt-1 text-xs font-medium text-emerald-600 dark:text-emerald-400">{trend}</p>
      ) : null}
    </div>
  );
}
