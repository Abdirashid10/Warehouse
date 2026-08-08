import { cn } from '../../lib/utils';



export function Badge({ className, variant = 'default', children }) {

  const variants = {

    default: 'bg-muted text-foreground ring-1 ring-border',

    accent: 'bg-sky-50 text-sky-800 ring-1 ring-sky-200 dark:bg-sky-500/20 dark:text-sky-300',

    success: 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200 dark:bg-emerald-500/20 dark:text-emerald-300',

    warning: 'bg-amber-50 text-amber-800 ring-1 ring-amber-200 dark:bg-amber-500/20 dark:text-amber-300',

    danger: 'bg-red-50 text-red-700 ring-1 ring-red-200 dark:bg-red-500/20 dark:text-red-300',

  };

  return <span className={cn('wms-badge', variants[variant], className)}>{children}</span>;

}


