import { useRef } from 'react';
import { ImagePlus, Trash2 } from 'lucide-react';
import { ProductImage } from './ProductImage';

export function ProductImageField({ previewSrc, onPickFile, onRemove, error, disabled }) {
  const fileRef = useRef(null);

  function handleFileChange(e) {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (file) onPickFile?.(file);
  }

  return (
    <div className="space-y-3">
      <p className="text-sm font-medium text-foreground">Product image</p>
      <div className="flex flex-wrap items-start gap-4">
        <ProductImage src={previewSrc} alt="Preview" size="lg" className="ring-1 ring-border" />
        <div className="flex min-w-[12rem] flex-1 flex-col gap-2">
          <input
            ref={fileRef}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            className="hidden"
            disabled={disabled}
            onChange={handleFileChange}
          />
          <button
            type="button"
            disabled={disabled}
            onClick={() => fileRef.current?.click()}
            className="inline-flex items-center justify-center gap-2 rounded-lg border border-border bg-background px-3 py-2 text-sm font-medium text-foreground transition hover:bg-muted"
          >
            <ImagePlus className="h-4 w-4 text-accent" />
            Choose image
          </button>
          {previewSrc && !disabled ? (
            <button
              type="button"
              onClick={onRemove}
              className="inline-flex items-center justify-center gap-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm font-medium text-red-700 transition hover:bg-red-100 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300 dark:hover:bg-red-500/20"
            >
              <Trash2 className="h-4 w-4" />
              Remove image
            </button>
          ) : null}
          <p className="text-xs text-muted-foreground">JPEG, PNG, or WebP · max 2MB</p>
          {error ? <p className="text-xs text-red-600">{error}</p> : null}
        </div>
      </div>
    </div>
  );
}
