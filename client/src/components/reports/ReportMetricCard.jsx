import { cn } from '../../lib/utils';

const ACCENT_ICON = {
  sky: 'bg-accent-soft text-accent dark:bg-sky-500/10 dark:text-sky-400 dark:ring-sky-500/20',
  emerald:
    'bg-emerald-100 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400 dark:ring-emerald-500/20',
  violet:
    'bg-violet-100 text-violet-700 dark:bg-violet-500/10 dark:text-violet-400 dark:ring-violet-500/20',
  amber:
    'bg-amber-100 text-amber-800 dark:bg-amber-500/10 dark:text-amber-400 dark:ring-amber-500/20',
};

const ACCENT_CARD = {
  sky: 'wms-kpi-card--sky',
  emerald: 'wms-kpi-card--emerald',
  amber: 'wms-kpi-card--amber',
  violet: 'wms-kpi-card--sky',
};

export function ReportMetricCard({ label, value, sub, icon: Icon, accent = 'sky' }) {
  const iconClass = ACCENT_ICON[accent] || ACCENT_ICON.sky;
  const cardAccent = ACCENT_CARD[accent] || ACCENT_CARD.sky;

  return (
    <div className={cn('wms-kpi-card relative overflow-hidden p-5', cardAccent)}>
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgb(var(--accent)/0.12),transparent_55%)] dark:bg-[radial-gradient(circle_at_top_right,rgb(var(--kpi-accent-sky)/0.08),transparent_55%)]" />
      <div className="relative flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <p className="wms-kpi-card__label text-[11px]">{label}</p>
          <p className="wms-kpi-card__value mt-2 text-2xl font-bold tracking-tight">{value}</p>
          {sub ? <p className="mt-1.5 text-xs text-muted-foreground">{sub}</p> : null}
        </div>
        {Icon ? (
          <div
            className={cn(
              'flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ring-1 ring-border/50',
              iconClass
            )}
          >
            <Icon className="h-5 w-5" strokeWidth={1.75} />
          </div>
        ) : null}
      </div>
    </div>
  );
}
