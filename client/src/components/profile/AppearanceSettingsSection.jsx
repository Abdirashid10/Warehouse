import { Monitor, Moon, Palette, Sun } from 'lucide-react';
import { useAppearance } from '../../context/AppearanceContext';
import { usePersistAppearance } from '../../hooks/usePersistAppearance';

export function AppearanceSettingsSection({ onPersist: onPersistProp }) {
  const { settings, accents } = useAppearance();
  const { updateAndPersist, isSaving } = usePersistAppearance();

  function handleChange(key, value) {
    if (onPersistProp) {
      onPersistProp({ ...settings, [key]: value });
    } else {
      updateAndPersist(key, value);
    }
  }

  return (
    <div className="space-y-6">
      {isSaving ? (
        <p className="text-xs text-muted-foreground">Saving preferences…</p>
      ) : null}

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
                onClick={() => handleChange('theme', opt.id)}
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
              onClick={() => handleChange('accent', accent)}
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
              onClick={() => handleChange('sidebarStyle', style)}
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
              onChange={(e) => handleChange(key, e.target.checked)}
              className="h-4 w-4 accent-[rgb(var(--accent))]"
            />
          </label>
        ))}
      </section>
    </div>
  );
}
