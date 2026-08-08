import { NavLink } from 'react-router-dom';
import { AnimatePresence, motion } from 'framer-motion';
import { ChevronLeft, ChevronRight, Package } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useAppearance } from '../../context/AppearanceContext';
import { ACCOUNT_NAV, getNavItems } from '../../config/navigation';
import { cn } from '../../lib/utils';

function SidebarLink({ item, compact, collapsed, onNavigate, isMobile }) {
  const Icon = item.icon;

  return (
    <NavLink
      to={item.to}
      onClick={onNavigate}
      title={collapsed ? item.label : undefined}
      className={({ isActive }) =>
        cn(
          'group relative flex items-center rounded-lg font-medium transition-all duration-200',
          isMobile ? 'text-[13px]' : 'text-base leading-snug',
          compact ? 'gap-2.5 px-2.5 py-2' : 'gap-3 px-3 py-2.5',
          collapsed ? 'justify-center px-2' : '',
          isActive
            ? 'bg-accent/10 font-semibold text-foreground shadow-sm'
            : isMobile
              ? 'text-sidebar-foreground hover:bg-muted/70 hover:text-foreground'
              : 'text-sidebar-foreground/90 hover:bg-muted/80 hover:text-foreground'
        )
      }
    >
      {({ isActive }) => (
        <>
          {isActive ? (
            <motion.span
              layoutId={isMobile ? 'sidebar-active-mobile' : 'sidebar-active'}
              className="absolute inset-y-1.5 left-0 w-0.5 rounded-full bg-accent"
              transition={{ type: 'spring', stiffness: 380, damping: 30 }}
            />
          ) : null}
          <Icon
            className={cn(
              'relative z-10 shrink-0',
              isMobile ? 'h-[18px] w-[18px]' : 'h-5 w-5',
              isActive
                ? 'text-accent'
                : isMobile
                  ? 'text-foreground/50 group-hover:text-foreground/80'
                  : 'text-muted-foreground group-hover:text-foreground'
            )}
          />
          {!collapsed ? <span className="relative z-10 truncate">{item.label}</span> : null}
        </>
      )}
    </NavLink>
  );
}

function NavGroup({ items, compact, collapsed, onNavigate, isMobile }) {
  return (
    <div className={cn('flex flex-col', isMobile ? 'gap-0.5' : 'gap-1')}>
      {items.map((item) => (
        <SidebarLink
          key={item.to}
          item={item}
          compact={compact}
          collapsed={collapsed}
          onNavigate={onNavigate}
          isMobile={isMobile}
        />
      ))}
    </div>
  );
}

export function Sidebar({ mobile = false, onNavigate }) {
  const { user } = useAuth();
  const { settings, toggleSidebarCollapsed } = useAppearance();
  const compact = settings.sidebarStyle === 'compact';
  const collapsed = !mobile && settings.sidebarCollapsed;

  const operationalItems = getNavItems(user);
  const personalItems = ACCOUNT_NAV;

  return (
    <aside
      className={cn(
        'flex h-full shrink-0 flex-col border-r border-border bg-sidebar',
        mobile ? 'w-full' : collapsed ? 'w-[72px]' : compact ? 'w-52' : 'w-60',
        !mobile && 'hidden lg:flex'
      )}
    >
      <div className={cn('shrink-0 border-b border-border', compact ? 'px-3 py-4' : 'px-4 py-4')}>
        {!collapsed ? (
          <>
            <p className={cn('font-semibold uppercase tracking-[0.2em] text-accent', mobile ? 'text-[10px]' : 'text-xs')}>
              Logistics WMS
            </p>
            <p className={cn('mt-1 font-semibold text-foreground', mobile ? 'text-base' : 'font-heading text-lg')}>
              Operations
            </p>
            {user?.role ? (
              <p className={cn('mt-1.5 text-muted-foreground', mobile ? 'text-xs' : 'text-sm')}>
                Signed in as <span className="font-medium text-foreground">{user.role}</span>
              </p>
            ) : null}
          </>
        ) : (
          <div className="mx-auto flex h-9 w-9 items-center justify-center rounded-lg bg-accent/10 text-accent">
            <Package className="h-4 w-4" />
          </div>
        )}
      </div>

      <nav
        className={cn(
          'flex min-h-0 flex-1 flex-col',
          compact ? 'px-2 py-3' : 'px-3 py-3'
        )}
      >
        <div className="min-h-0 flex-1 overflow-y-auto">
          <NavGroup
            items={operationalItems}
            compact={compact}
            collapsed={collapsed}
            onNavigate={onNavigate}
            isMobile={mobile}
          />
        </div>

        <div className={cn('shrink-0 pt-3', compact ? 'space-y-2' : 'space-y-2.5')}>
          <div
            className={cn(
              'border-t border-border/80',
              collapsed ? 'mx-1' : 'mx-0'
            )}
            role="separator"
            aria-hidden
          />
          {!collapsed ? (
            <p
              className={cn(
                'px-3 font-semibold uppercase tracking-[0.14em] text-muted-foreground',
                mobile ? 'text-[10px]' : 'text-xs'
              )}
            >
              Account
            </p>
          ) : null}
          <NavGroup
            items={personalItems}
            compact={compact}
            collapsed={collapsed}
            onNavigate={onNavigate}
            isMobile={mobile}
          />
        </div>
      </nav>

      {!mobile ? (
        <div className={cn('shrink-0 border-t border-border', compact ? 'p-2' : 'p-3')}>
          <button
            type="button"
            onClick={toggleSidebarCollapsed}
            className="flex w-full items-center justify-center rounded-lg border border-border bg-background px-2 py-1.5 text-muted-foreground transition hover:bg-muted hover:text-foreground"
            aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
          </button>
        </div>
      ) : null}
    </aside>
  );
}

export function MobileSidebarDrawer({ open, onClose }) {
  return (
    <AnimatePresence>
      {open ? (
        <div className="fixed inset-0 z-[60] lg:hidden">
          <motion.button
            type="button"
            className="absolute inset-0 bg-slate-900/20 backdrop-blur-sm"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            aria-label="Close menu"
          />
          <motion.div
            initial={{ x: '-100%' }}
            animate={{ x: 0 }}
            exit={{ x: '-100%' }}
            transition={{ type: 'spring', stiffness: 320, damping: 32 }}
            className="relative h-full w-[85vw] max-w-xs shadow-card-hover"
          >
            <Sidebar mobile onNavigate={onClose} />
          </motion.div>
        </div>
      ) : null}
    </AnimatePresence>
  );
}
