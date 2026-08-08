import { cn } from '../../lib/utils';

export function TableShell({ className, children }) {
  return (
    <div className={cn('wms-table-shell overflow-x-auto', className)}>
      <table className="min-w-full text-left text-sm">{children}</table>
    </div>
  );
}

export function TableHead({ children }) {
  return <thead>{children}</thead>;
}

export function TableBody({ children }) {
  return <tbody className="divide-y divide-border">{children}</tbody>;
}

export function TableRow({ className, children }) {
  return <tr className={cn('transition hover:bg-muted/60', className)}>{children}</tr>;
}

export function TableHeaderCell({ className, children }) {
  return <th className={cn('px-4 py-3.5', className)}>{children}</th>;
}

export function TableCell({ className, children }) {
  return <td className={cn('px-4 py-3 text-foreground', className)}>{children}</td>;
}
