import { useAppearance } from '../context/AppearanceContext';

export function useChartTheme() {
  const { resolvedTheme } = useAppearance();
  const isDark = resolvedTheme === 'dark';

  return {
    isDark,

    /* Surfaces */
    grid: isDark ? 'rgba(51,65,85,0.35)' : 'rgba(226,232,240,0.6)',
    axis: isDark ? '#64748b' : '#94a3b8',
    legendText: isDark ? '#94a3b8' : '#64748b',

    /* Tooltip */
    tooltipBg: isDark ? 'rgba(15,23,42,0.96)' : 'rgba(255,255,255,0.98)',
    tooltipBorder: isDark ? 'rgba(51,65,85,0.5)' : 'rgba(226,232,240,0.8)',
    tooltipText: isDark ? '#e2e8f0' : '#1e293b',
    tooltipShadow: isDark
      ? '0 12px 40px rgb(0 0 0 / 0.5), 0 0 0 1px rgb(255 255 255 / 0.05)'
      : '0 8px 32px rgb(0 0 0 / 0.08), 0 0 0 1px rgb(0 0 0 / 0.03)',

    /* Cursor hover fill */
    cursorFill: isDark ? 'rgba(148,163,184,0.06)' : 'rgba(0,0,0,0.025)',

    /* Semantic colors — movement */
    inbound: isDark ? '#34d399' : '#10b981',
    inboundLight: isDark ? 'rgba(52,211,153,0.15)' : 'rgba(16,185,129,0.1)',
    outbound: isDark ? '#f87171' : '#ef4444',
    outboundLight: isDark ? 'rgba(248,113,113,0.15)' : 'rgba(239,68,68,0.1)',
    transfer: isDark ? '#38bdf8' : '#0ea5e9',

    /* Semantic colors — orders pipeline */
    pending: isDark ? '#94a3b8' : '#64748b',
    processing: isDark ? '#38bdf8' : '#0ea5e9',
    packed: isDark ? '#a78bfa' : '#8b5cf6',
    shipped: isDark ? '#fbbf24' : '#f59e0b',
    delivered: isDark ? '#34d399' : '#10b981',

    /* Accent / generic */
    primary: 'rgb(var(--accent))',
    primaryLight: isDark ? 'rgba(56,189,248,0.12)' : 'rgba(14,165,233,0.08)',
    secondary: isDark ? '#a78bfa' : '#8b5cf6',
    secondaryLight: isDark ? 'rgba(167,139,250,0.12)' : 'rgba(139,92,246,0.08)',

    /* Inventory health */
    healthy: isDark ? '#34d399' : '#10b981',
    warning: isDark ? '#fbbf24' : '#f59e0b',
    critical: isDark ? '#f87171' : '#ef4444',
  };
}

export function chartTooltipStyle(c) {
  return {
    backgroundColor: c.tooltipBg,
    border: `1px solid ${c.tooltipBorder}`,
    borderRadius: '10px',
    color: c.tooltipText,
    boxShadow: c.tooltipShadow,
    fontSize: '12px',
    fontWeight: 500,
    padding: '10px 14px',
    backdropFilter: 'blur(8px)',
    lineHeight: 1.5,
  };
}

export function chartAxisProps(c) {
  return {
    tick: { fill: c.axis, fontSize: 11, fontWeight: 500 },
    axisLine: false,
    tickLine: false,
  };
}

export function chartLegendProps(c) {
  return {
    wrapperStyle: { color: c.legendText, fontSize: 11, fontWeight: 500, paddingTop: '6px' },
    iconType: 'circle',
    iconSize: 8,
  };
}
