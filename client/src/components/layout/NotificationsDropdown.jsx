import { useState } from 'react';
import { Link } from 'react-router-dom';
import { AnimatePresence, motion } from 'framer-motion';
import { Bell, CheckCheck, ExternalLink } from 'lucide-react';
import {
  useNotifications,
  useUnreadCount,
  useNotificationMutations,
} from '../../hooks/useNotifications';
import { NotificationCard } from '../notifications/NotificationCard';
import { Button } from '../ui/button';

export function NotificationsDropdown() {
  const [open, setOpen] = useState(false);
  const { data: unreadData } = useUnreadCount();
  const { data, isLoading } = useNotifications({ limit: 12 }, { enabled: open });
  const { markRead, markAllRead } = useNotificationMutations();

  const unreadCount = unreadData?.unreadCount ?? 0;
  const items = data?.notifications || [];

  const displayCount = unreadCount > 99 ? '99+' : unreadCount;

  return (
    <div className="relative">
      <Button variant="ghost" size="sm" className="relative px-2.5" onClick={() => setOpen((v) => !v)}>
        <Bell className="h-4 w-4" />
        {unreadCount > 0 ? (
          <motion.span
            key={unreadCount}
            initial={{ scale: 0.6, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-accent px-1 text-[10px] font-bold text-white"
          >
            {displayCount}
          </motion.span>
        ) : null}
      </Button>
      <AnimatePresence>
        {open ? (
          <>
            <button
              type="button"
              className="fixed inset-0 z-40"
              onClick={() => setOpen(false)}
              aria-label="Close notifications"
            />
            <motion.div
              initial={{ opacity: 0, y: 8, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 6, scale: 0.98 }}
              transition={{ duration: 0.16 }}
              className="absolute right-0 z-50 mt-2 w-[min(92vw,26rem)] overflow-hidden rounded-2xl border border-border bg-card shadow-2xl"
            >
              <div className="flex items-center justify-between gap-2 border-b border-border px-4 py-3">
                <div>
                  <p className="text-sm font-semibold text-foreground">Notifications</p>
                  <p className="text-xs text-muted-foreground">
                    {unreadCount > 0 ? `${unreadCount} unread` : 'All caught up'}
                  </p>
                </div>
                {unreadCount > 0 ? (
                  <Button
                    variant="ghost"
                    size="sm"
                    className="h-8 gap-1 text-xs"
                    onClick={() => markAllRead.mutate()}
                    disabled={markAllRead.isPending}
                  >
                    <CheckCheck className="h-3.5 w-3.5" />
                    Mark all read
                  </Button>
                ) : null}
              </div>
              <div className="max-h-80 overflow-y-auto p-2">
                {isLoading ? (
                  <p className="px-3 py-8 text-center text-sm text-muted-foreground">Loading…</p>
                ) : items.length === 0 ? (
                  <p className="px-3 py-8 text-center text-sm text-muted-foreground">You&apos;re all caught up.</p>
                ) : (
                  items.map((n) => (
                    <NotificationCard
                      key={n.id}
                      notification={n}
                      compact
                      onMarkRead={(id) => markRead.mutate(id)}
                      onNavigate={() => setOpen(false)}
                    />
                  ))
                )}
              </div>
              <div className="border-t border-border px-3 py-2">
                <Link
                  to="/notifications"
                  onClick={() => setOpen(false)}
                  className="flex items-center justify-center gap-1.5 rounded-lg py-2 text-xs font-medium text-accent transition hover:bg-accent/5"
                >
                  View all notifications
                  <ExternalLink className="h-3 w-3" />
                </Link>
              </div>
            </motion.div>
          </>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
