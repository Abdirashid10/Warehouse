import { cn } from '../../lib/utils';

export function Button({ className, variant = 'primary', size = 'md', ...props }) {
  const variants = {
    primary: 'wms-btn-primary',
    secondary: 'wms-btn-secondary',
    ghost: 'wms-btn text-foreground/80 hover:bg-muted hover:text-foreground',
    danger: 'wms-btn bg-red-600 text-white hover:bg-red-500',
  };
  const sizes = {
    sm: 'px-3 py-1.5 text-xs',
    md: '',
    lg: 'px-5 py-3 text-base',
  };
  return <button className={cn(variants[variant], sizes[size], className)} {...props} />;
}
