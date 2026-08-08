import { cn } from '../../lib/utils';

export function Input({ className, ...props }) {
  return <input className={cn('wms-input', className)} {...props} />;
}

export function Textarea({ className, ...props }) {
  return <textarea className={cn('wms-input min-h-[96px] resize-y', className)} {...props} />;
}

export function Label({ className, children, ...props }) {
  return (
    <label className={cn('block text-sm font-medium text-foreground', className)} {...props}>
      {children}
    </label>
  );
}

export function Field({ label, hint, error, children, required }) {
  return (
    <div className="space-y-1.5">
      {label ? (
        <Label>
          {label}
          {required ? <span className="ml-1 text-red-500">*</span> : null}
        </Label>
      ) : null}
      {children}
      {error ? <p className="text-xs text-red-500">{error}</p> : null}
      {!error && hint ? <p className="text-xs text-muted-foreground">{hint}</p> : null}
    </div>
  );
}
