import { Link, useLocation } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ChevronRight } from 'lucide-react';
import { useAppearance } from '../../context/AppearanceContext';
import { cn } from '../../lib/utils';

const ROUTE_LABELS = {
  dashboard: 'Dashboard',
  products: 'Products',
  'inventory-tracking': 'Inventory Tracking',
  'stock-movements': 'Stock Movements',
  warehouses: 'Warehouses',
  orders: 'Orders',
  tasks: 'Tasks',
  reports: 'Reports',
  users: 'User Management',
  profile: 'My Profile',
  notifications: 'Notifications',
};

export function PageShell({ title, subtitle, actions, children, className }) {
  const location = useLocation();
  const { settings } = useAppearance();
  const segments = location.pathname.split('/').filter(Boolean);
  const crumbs = segments.map((seg, idx) => ({
    label: ROUTE_LABELS[seg] || seg,
    path: `/${segments.slice(0, idx + 1).join('/')}`,
    last: idx === segments.length - 1,
  }));

  const content = (
    <div className={cn('space-y-6', className)}>
      <div className="flex flex-col gap-4 border-b border-border pb-5 sm:flex-row sm:items-end sm:justify-between">
        <div>
          {settings.breadcrumbs && crumbs.length > 0 ? (
            <nav className="mb-2 flex flex-wrap items-center gap-1 text-xs text-muted-foreground">
              <Link to="/dashboard" className="hover:text-foreground">
                Home
              </Link>
              {crumbs.map((c) => (
                <span key={c.path} className="inline-flex items-center gap-1">
                  <ChevronRight className="h-3 w-3" />
                  {c.last ? (
                    <span className="font-medium text-foreground">{c.label}</span>
                  ) : (
                    <Link to={c.path} className="hover:text-foreground">
                      {c.label}
                    </Link>
                  )}
                </span>
              ))}
            </nav>
          ) : null}
          <h1 className="wms-page-title">{title}</h1>
          {subtitle ? <p className="wms-page-subtitle">{subtitle}</p> : null}
        </div>
        {actions ? <div className="flex flex-wrap items-center gap-2">{actions}</div> : null}
      </div>
      {children}
    </div>
  );

  if (!settings.animations) return content;

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.22, ease: 'easeOut' }}
    >
      {content}
    </motion.div>
  );
}
