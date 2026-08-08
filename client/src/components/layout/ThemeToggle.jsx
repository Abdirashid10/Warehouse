import { Moon, Sun } from 'lucide-react';
import { useAppearance } from '../../context/AppearanceContext';
import { usePersistAppearance } from '../../hooks/usePersistAppearance';
import { Button } from '../ui/button';

export function ThemeToggle() {
  const { resolvedTheme } = useAppearance();
  const { updateAndPersist } = usePersistAppearance();
  const isDark = resolvedTheme === 'dark';

  return (
    <Button
      variant="ghost"
      size="sm"
      className="hidden px-2.5 lg:inline-flex"
      onClick={() => updateAndPersist('theme', isDark ? 'light' : 'dark')}
      aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      title={isDark ? 'Light mode' : 'Dark mode'}
    >
      {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
    </Button>
  );
}
