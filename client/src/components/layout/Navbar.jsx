import { Menu, Search } from 'lucide-react';
import { Button } from '../ui/button';
import { CommandPalette, useCommandPalette } from './CommandPalette';
import { NotificationsDropdown } from './NotificationsDropdown';
import { ProfileDropdown } from './ProfileDropdown';
import { ThemeToggle } from './ThemeToggle';

export function Navbar({ onOpenMobileSidebar }) {
  const { open: commandOpen, setOpen: setCommandOpen } = useCommandPalette();

  return (
    <>
      <header className="sticky top-0 z-40 flex h-14 shrink-0 items-center justify-between border-b border-border bg-card px-4 shadow-sm backdrop-blur-xl sm:px-6">
        <div className="flex items-center gap-3">
          <Button variant="ghost" size="sm" className="lg:hidden" onClick={onOpenMobileSidebar}>
            <Menu className="h-4 w-4" />
          </Button>
          <div>
            <p className="text-sm font-medium text-foreground lg:font-heading lg:text-base lg:font-semibold">
              Warehouse Control Center
            </p>
            <p className="hidden text-xs text-muted-foreground sm:block">
              Premium enterprise logistics workspace
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2 sm:gap-3">
          <button
            type="button"
            className="relative hidden h-[46px] w-[360px] items-center rounded-lg border border-border bg-card pl-10 pr-3 text-left text-sm font-medium text-muted-foreground transition hover:border-accent/40 hover:bg-muted/30 focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent/20 lg:flex"
            onClick={() => setCommandOpen(true)}
            aria-label="Open search"
          >
            <Search className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <span>Search…</span>
            <kbd className="ml-auto rounded-md border border-border bg-muted px-1.5 py-0.5 text-[10px] font-semibold text-foreground/70">
              Ctrl K
            </kbd>
          </button>
          <Button variant="ghost" size="sm" className="lg:hidden" onClick={() => setCommandOpen(true)}>
            <Search className="h-4 w-4" />
          </Button>
          <ThemeToggle />
          <NotificationsDropdown />
          <ProfileDropdown />
        </div>
      </header>

      <CommandPalette open={commandOpen} onClose={() => setCommandOpen(false)} />
    </>
  );
}
