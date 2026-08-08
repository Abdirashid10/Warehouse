import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';

const STORAGE_KEY = 'logistics-wms-appearance';

const ACCENTS = {
  sky: { primary: '14 165 233', ring: '56 189 248' },
  violet: { primary: '139 92 246', ring: '167 139 250' },
  emerald: { primary: '16 185 129', ring: '52 211 153' },
  rose: { primary: '244 63 94', ring: '251 113 133' },
  amber: { primary: '245 158 11', ring: '251 191 36' },
};

const DEFAULT_SETTINGS = {
  theme: 'system',
  accent: 'sky',
  sidebarStyle: 'default',
  animations: true,
  compactTables: true,
  breadcrumbs: true,
  sidebarCollapsed: false,
};

function readStoredSettings() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return DEFAULT_SETTINGS;
    return { ...DEFAULT_SETTINGS, ...JSON.parse(raw) };
  } catch {
    return DEFAULT_SETTINGS;
  }
}

function resolveThemeMode(theme) {
  if (theme === 'system') {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  return theme;
}

const AppearanceContext = createContext(null);

export function AppearanceProvider({ children }) {
  const [settings, setSettings] = useState(readStoredSettings);
  const [resolvedTheme, setResolvedTheme] = useState(() => resolveThemeMode(readStoredSettings().theme));

  const persist = useCallback((nextOrUpdater) => {
    setSettings((prev) => {
      const next = typeof nextOrUpdater === 'function' ? nextOrUpdater(prev) : nextOrUpdater;
      localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
      return next;
    });
  }, []);

  const updateSetting = useCallback(
    (key, value) => {
      let nextSettings = null;
      persist((prev) => {
        nextSettings = { ...prev, [key]: value };
        return nextSettings;
      });
      return nextSettings;
    },
    [persist]
  );

  const resetSettings = useCallback(() => {
    persist(DEFAULT_SETTINGS);
    return DEFAULT_SETTINGS;
  }, [persist]);

  const hydrateFromServer = useCallback(
    (serverPrefs) => {
      if (!serverPrefs || typeof serverPrefs !== 'object') return;
      persist({ ...DEFAULT_SETTINGS, ...serverPrefs });
    },
    [persist]
  );

  useEffect(() => {
    const mode = resolveThemeMode(settings.theme);
    setResolvedTheme(mode);
    document.documentElement.classList.toggle('dark', mode === 'dark');
    document.documentElement.dataset.theme = mode;

    const accent = ACCENTS[settings.accent] || ACCENTS.sky;
    document.documentElement.style.setProperty('--accent', accent.primary);
    document.documentElement.style.setProperty('--accent-ring', accent.ring);
    document.documentElement.dataset.sidebar = settings.sidebarStyle;
    document.documentElement.dataset.compactTables = settings.compactTables ? 'true' : 'false';
    document.documentElement.dataset.animations = settings.animations ? 'true' : 'false';
  }, [settings]);

  useEffect(() => {
    if (settings.theme !== 'system') return undefined;
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const handler = () => setResolvedTheme(resolveThemeMode('system'));
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, [settings.theme]);

  const value = useMemo(
    () => ({
      settings,
      resolvedTheme,
      accents: Object.keys(ACCENTS),
      updateSetting,
      resetSettings,
      hydrateFromServer,
      toggleSidebarCollapsed: () => updateSetting('sidebarCollapsed', !settings.sidebarCollapsed),
    }),
    [settings, resolvedTheme, updateSetting, resetSettings, hydrateFromServer]
  );

  return <AppearanceContext.Provider value={value}>{children}</AppearanceContext.Provider>;
}

export function useAppearance() {
  const ctx = useContext(AppearanceContext);
  if (!ctx) throw new Error('useAppearance must be used within AppearanceProvider');
  return ctx;
}
