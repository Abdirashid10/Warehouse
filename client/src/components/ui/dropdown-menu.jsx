import { useEffect, useRef, useState } from 'react';
import { MoreVertical } from 'lucide-react';
import { cn } from '../../lib/utils';

export function DropdownMenu({ trigger, children, align = 'end', className }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (!open) return undefined;
    function handleClick(event) {
      if (!ref.current?.contains(event.target)) setOpen(false);
    }
    function handleKey(event) {
      if (event.key === 'Escape') setOpen(false);
    }
    document.addEventListener('mousedown', handleClick);
    document.addEventListener('keydown', handleKey);
    return () => {
      document.removeEventListener('mousedown', handleClick);
      document.removeEventListener('keydown', handleKey);
    };
  }, [open]);

  return (
    <div className={cn('relative inline-block text-left', className)} ref={ref}>
      <div onClick={() => setOpen((value) => !value)}>{trigger}</div>
      {open ? (
        <div
          className={cn(
            'absolute z-50 mt-1 min-w-[11.5rem] overflow-hidden rounded-xl border border-border bg-card py-1 shadow-card-hover',
            align === 'end' ? 'right-0' : 'left-0'
          )}
          role="menu"
        >
          {typeof children === 'function' ? children(() => setOpen(false)) : children}
        </div>
      ) : null}
    </div>
  );
}

export function DropdownMenuTrigger({ className, ...props }) {
  return (
    <button
      type="button"
      className={cn(
        'inline-flex h-8 w-8 items-center justify-center rounded-lg border border-border bg-card text-muted-foreground transition hover:bg-muted hover:text-foreground',
        className
      )}
      aria-label="Open actions menu"
      {...props}
    >
      <MoreVertical className="h-4 w-4" />
    </button>
  );
}

export function DropdownMenuItem({
  icon: Icon,
  label,
  onClick,
  variant = 'default',
  disabled = false,
  close,
}) {
  const variants = {
    default: 'text-foreground hover:bg-muted',
    primary: 'text-violet-700 hover:bg-violet-50 dark:text-violet-300 dark:hover:bg-violet-500/10',
    warning: 'text-amber-700 hover:bg-amber-50 dark:text-amber-300 dark:hover:bg-amber-500/10',
    danger: 'text-red-600 hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-500/10',
  };

  return (
    <button
      type="button"
      role="menuitem"
      disabled={disabled}
      onClick={() => {
        if (disabled) return;
        onClick?.();
        close?.();
      }}
      className={cn(
        'flex w-full items-center gap-2.5 px-3 py-2 text-left text-sm font-medium transition disabled:cursor-not-allowed disabled:opacity-40',
        variants[variant]
      )}
    >
      {Icon ? <Icon className="h-4 w-4 shrink-0 opacity-75" /> : null}
      {label}
    </button>
  );
}

export function DropdownMenuSeparator() {
  return <div className="my-1 border-t border-border" role="separator" />;
}
