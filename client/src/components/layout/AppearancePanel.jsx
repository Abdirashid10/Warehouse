import { AnimatePresence, motion } from 'framer-motion';
import { Monitor, Moon, Palette, RotateCcw, Settings2, Sun, X } from 'lucide-react';
import { useAppearance } from '../../context/AppearanceContext';
import { usePersistAppearance } from '../../hooks/usePersistAppearance';
import { Button } from '../ui/button';

export function AppearancePanel({ open, onClose }) {
  const { settings, accents } = useAppearance();
  const { updateAndPersist, resetAndPersist, isSaving } = usePersistAppearance();

  return (
    <AnimatePresence>
      {open ? (
        <>
          <motion.button
            type="button"
            className="fixed inset-0 z-[70] bg-black/40 backdrop-blur-[1px]"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            aria-label="Close appearance settings"
          />
          <motion.aside
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', stiffness: 320, damping: 32 }}
            className="fixed right-0 top-0 z-[71] flex h-full w-full max-w-md flex-col border-l border-border bg-card shadow-2xl"
          >
            <div className="flex items-center justify-between border-b border-border px-5 py-4">
              <div>
                <p className="flex items-center gap-2 text-sm font-semibold text-foreground">
                  <Settings2 className="h-4 w-4 text-accent" />
                  Appearance
                </p>
                <p className="text-xs text-muted-foreground">
                  Saved to your profile{isSaving ? '…' : ''}
                </p>
              </div>
              <Button variant="ghost" size="sm" onClick={onClose}>
                <X className="h-4 w-4" />
              </Button>
            </div>

            <div className="flex-1 space-y-6 overflow-y-auto p-5">
              <section>
                <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-muted-foreground">Theme</p>
                <div className="grid grid-cols-3 gap-2">
                  {[
                    { id: 'light', label: 'Light', icon: Sun },
                    { id: 'dark', label: 'Dark', icon: Moon },
                    { id: 'system', label: 'System', icon: Monitor },
                  ].map((opt) => {
                    const Icon = opt.icon;
                    const active = settings.theme === opt.id;
                    return (
                      <button
                        key={opt.id}
                        type="button"
                        onClick={() => updateAndPersist('theme', opt.id)}
                        className={`rounded-xl border px-3 py-3 text-left transition ${
                          active
                            ? 'border-accent bg-accent-soft shadow-glow'
                            : 'border-border bg-background hover:bg-muted'
                        }`}
                      >
                        <Icon className={`h-4 w-4 ${active ? 'text-accent' : 'text-muted-foreground'}`} />
                        <p className="mt-2 text-sm font-medium text-foreground">{opt.label}</p>
                      </button>
                    );
                  })}
                </div>
              </section>

              <section>
                <p className="mb-3 flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                  <Palette className="h-3.5 w-3.5" />
                  Accent color
                </p>
                <div className="flex flex-wrap gap-2">
                  {accents.map((accent) => (
                    <button
                      key={accent}
                      type="button"
                      onClick={() => updateAndPersist('accent', accent)}
                      className={`rounded-full px-3 py-1.5 text-xs font-semibold capitalize transition ${
                        settings.accent === accent
                          ? 'bg-accent text-white shadow-glow'
                          : 'border border-border bg-background text-foreground hover:bg-muted'
                      }`}
                    >
                      {accent}
                    </button>
                  ))}
                </div>
              </section>

              <section>
                <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-muted-foreground">Sidebar style</p>
                <div className="grid grid-cols-2 gap-2">
                  {['default', 'compact'].map((style) => (
                    <button
                      key={style}
                      type="button"
                      onClick={() => updateAndPersist('sidebarStyle', style)}
                      className={`rounded-xl border px-3 py-2.5 text-sm capitalize transition ${
                        settings.sidebarStyle === style
                          ? 'border-accent bg-accent-soft text-foreground'
                          : 'border-border bg-background hover:bg-muted'
                      }`}
                    >
                      {style}
                    </button>
                  ))}
                </div>
              </section>

              <section className="space-y-3">
                {[
                  ['animations', 'Enable animations'],
                  ['compactTables', 'Compact tables'],
                  ['breadcrumbs', 'Show breadcrumbs'],
                ].map(([key, label]) => (
                  <label
                    key={key}
                    className="flex items-center justify-between rounded-xl border border-border bg-background px-3 py-3"
                  >
                    <span className="text-sm text-foreground">{label}</span>
                    <input
                      type="checkbox"
                      checked={Boolean(settings[key])}
                      onChange={(e) => updateAndPersist(key, e.target.checked)}
                      className="h-4 w-4 accent-[rgb(var(--accent))]"
                    />
                  </label>
                ))}
              </section>
            </div>

            <div className="border-t border-border p-4">
              <Button variant="secondary" className="w-full" onClick={resetAndPersist} disabled={isSaving}>
                <RotateCcw className="h-4 w-4" />
                Reset appearance
              </Button>
            </div>
          </motion.aside>
        </>
      ) : null}
    </AnimatePresence>
  );
}
