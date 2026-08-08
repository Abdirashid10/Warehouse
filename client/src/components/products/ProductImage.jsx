import { useState } from 'react';
import { Boxes } from 'lucide-react';
import { cn } from '../../lib/utils';
import { resolveProductImageUrl } from '../../utils/productImage';

const SIZE_MAP = {
  sm: 'h-10 w-10',
  md: 'h-16 w-16',
  lg: 'h-24 w-24',
};

export function ProductImage({ src, alt = 'Product', size = 'sm', className }) {
  const [failed, setFailed] = useState(false);
  const resolved = resolveProductImageUrl(src);
  const sizeClass = SIZE_MAP[size] || SIZE_MAP.sm;

  if (!resolved || failed) {
    return (
      <div
        className={cn(
          'flex shrink-0 items-center justify-center rounded-lg border border-border bg-muted text-muted-foreground',
          sizeClass,
          className
        )}
        aria-hidden
      >
        <Boxes className={size === 'lg' ? 'h-8 w-8' : 'h-4 w-4'} />
      </div>
    );
  }

  return (
    <img
      src={resolved}
      alt={alt}
      onError={() => setFailed(true)}
      className={cn('shrink-0 rounded-lg border border-border object-cover', sizeClass, className)}
    />
  );
}
